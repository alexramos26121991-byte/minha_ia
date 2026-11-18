import 'package:flutter/foundation.dart';

import 'generation_models.dart';
import 'generation_sources.dart';

/// Estado da carga inicial (saldo + custos).
enum GenerationLoadState { initial, loading, ready, error }

/// Resultado da última tentativa de geração.
enum GenerateState { idle, generating, success, error }

/// Desfecho de uma geração, usado pela UI para escolher a mensagem.
enum GenerateOutcome { success, insufficientBalance, error }

/// Coordena saldo, custos, geração e galeria.
///
/// Toda decisão de preço vem do backend (`GET /credits/costs`); o app apenas
/// exibe o valor e avisa quando o saldo disponível é menor que o custo.
class GenerationController extends ChangeNotifier {
  GenerationController({
    required CreditSource credits,
    required GenerationSource generations,
  })  : _credits = credits,
        _generations = generations;

  final CreditSource _credits;
  final GenerationSource _generations;

  GenerationLoadState loadState = GenerationLoadState.initial;
  GenerateState generateState = GenerateState.idle;
  GenerateOutcome? lastOutcome;

  String? errorMessage;
  String? itemsErrorMessage;
  bool insufficientBalance = false;
  bool uploading = false;
  String? uploadedImageUrl;

  CreditBalance? balance;
  List<GenerationCost> costs = const <GenerationCost>[];
  List<GenerationItem> items = const <GenerationItem>[];
  GenerationFilter filter = GenerationFilter.images;
  GenerationItem? lastGenerated;
  GenerationKind? lastKind;

  /// Custo real da geração de imagem, vindo do backend.
  int get imageCost => _costFor('image');

  /// Custo de um vídeo a partir de texto (E5).
  int get videoCost => _costFor('video');

  /// Custo da animação de uma foto (E5).
  int get animatePhotoCost => _costFor('animate_photo');

  int _costFor(String operation) {
    for (final cost in costs) {
      if (cost.operation == operation && cost.enabled) return cost.credits;
    }
    return 0;
  }

  int? get availableCredits => balance?.available;

  /// Busca saldo e custos. Segunda chamada sem `force` não refaz a requisição.
  Future<void> load({bool force = false}) async {
    if (loadState == GenerationLoadState.loading) return;
    if (loadState == GenerationLoadState.ready && !force) return;

    loadState = GenerationLoadState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait<Object>([
        _credits.getBalance(),
        _credits.listCosts(),
      ]);
      balance = results[0] as CreditBalance;
      costs = results[1] as List<GenerationCost>;
      loadState = GenerationLoadState.ready;
    } catch (error) {
      errorMessage = _message(error);
      loadState = GenerationLoadState.error;
    }
    notifyListeners();
    await loadItems();
  }

  /// Recarrega apenas a galeria, respeitando o filtro atual.
  Future<void> loadItems() async {
    if (!filter.hasBackendData) {
      items = const <GenerationItem>[];
      itemsErrorMessage = null;
      notifyListeners();
      return;
    }
    try {
      items = await _generations.listGenerations(filter: filter, limit: 50);
      itemsErrorMessage = null;
    } catch (error) {
      items = const <GenerationItem>[];
      itemsErrorMessage = _message(error);
    }
    notifyListeners();
  }

  Future<void> setFilter(GenerationFilter value) async {
    if (filter == value) return;
    filter = value;
    notifyListeners();
    await loadItems();
  }

  /// Gera uma imagem. Nunca debita diretamente: o backend é a fonte da verdade.
  Future<GenerateOutcome> generateImage({
    required String prompt,
    String? style,
    String? size,
  }) {
    return _run(
      kind: GenerationKind.image,
      cost: imageCost,
      inputText: prompt,
      emptyMessage: 'Descreva o que você quer criar.',
      call: () => _generations.generateImage(
        prompt: prompt.trim(),
        style: style,
        size: size,
      ),
    );
  }

  /// Enfileira um vídeo a partir de texto (E5).
  Future<GenerateOutcome> generateVideo({
    required String prompt,
    int? durationSeconds,
    String? resolution,
  }) {
    return _run(
      kind: GenerationKind.video,
      cost: videoCost,
      inputText: prompt,
      emptyMessage: 'Descreva o que você quer criar.',
      call: () => _generations.generateVideo(
        prompt: prompt.trim(),
        durationSeconds: durationSeconds,
        resolution: resolution,
      ),
    );
  }

  /// Anima uma imagem já hospedada, normalmente enviada por `uploadImage`.
  Future<GenerateOutcome> animatePhoto({
    required String imageUrl,
    String? motion,
  }) {
    final url = imageUrl.trim();
    return _run(
      kind: GenerationKind.animatePhoto,
      cost: animatePhotoCost,
      inputText: url,
      emptyMessage: 'Escolha uma imagem para animar.',
      call: () => _generations.animatePhoto(imageUrl: url, motion: motion),
    );
  }

  /// Envia os bytes da foto ao backend e guarda a URL HTTPS devolvida.
  Future<bool> uploadImage(
    Uint8List bytes, {
    required String fileName,
    required String mimeType,
  }) async {
    uploading = true;
    errorMessage = null;
    notifyListeners();
    try {
      uploadedImageUrl = await _generations.uploadImage(
        bytes,
        fileName: fileName,
        mimeType: mimeType,
      );
      return true;
    } catch (error) {
      errorMessage = _message(error);
      return false;
    } finally {
      uploading = false;
      notifyListeners();
    }
  }

  /// Polling de fallback: atualiza o progresso até o job terminar.
  ///
  /// O webhook é o caminho preferencial no backend; isto cobre o caso de o
  /// dispositivo não receber a notificação. Intervalo e tentativas são
  /// injetáveis para que os testes sejam instantâneos.
  Future<GenerationItem?> pollGeneration(
    String id, {
    Duration interval = const Duration(seconds: 2),
    int maxAttempts = 60,
    bool Function()? shouldStop,
  }) async {
    if (id.isEmpty) return null;
    GenerationItem? current;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (shouldStop != null && shouldStop()) return current;
      try {
        current = await _generations.getGeneration(id);
      } catch (_) {
        // Uma falha pontual não descarta o último progresso conhecido.
        return current;
      }
      lastGenerated = current;
      notifyListeners();
      if (current.isTerminal) {
        await _refreshBalanceAndItems();
        return current;
      }
      if (attempt + 1 < maxAttempts) await Future<void>.delayed(interval);
    }
    return current;
  }

  Future<GenerateOutcome> _run({
    required GenerationKind kind,
    required int cost,
    required String inputText,
    required String emptyMessage,
    required Future<GenerationItem> Function() call,
  }) async {
    if (inputText.trim().isEmpty) {
      errorMessage = emptyMessage;
      insufficientBalance = false;
      lastKind = kind;
      lastOutcome = GenerateOutcome.error;
      generateState = GenerateState.error;
      notifyListeners();
      return GenerateOutcome.error;
    }

    final available = balance?.available;
    if (cost > 0 && available != null && available < cost) {
      errorMessage = 'Saldo insuficiente: esta criação custa $cost créditos.';
      insufficientBalance = true;
      lastKind = kind;
      lastOutcome = GenerateOutcome.insufficientBalance;
      generateState = GenerateState.error;
      notifyListeners();
      return GenerateOutcome.insufficientBalance;
    }

    generateState = GenerateState.generating;
    errorMessage = null;
    insufficientBalance = false;
    lastGenerated = null;
    lastKind = kind;
    lastOutcome = null;
    notifyListeners();

    try {
      final item = await call();
      lastGenerated = item;
      generateState = GenerateState.success;
      lastOutcome = GenerateOutcome.success;
      notifyListeners();

      // Atualiza saldo e galeria em segundo plano: uma falha aqui não desfaz
      // uma geração que o backend já entregou/enfileirou.
      await _refreshBalanceAndItems();
      return GenerateOutcome.success;
    } catch (error) {
      generateState = GenerateState.error;
      errorMessage = _message(error);
      insufficientBalance =
          error is GenerationApiFailure && error.isInsufficientBalance;
      lastOutcome = insufficientBalance
          ? GenerateOutcome.insufficientBalance
          : GenerateOutcome.error;
      notifyListeners();
      return lastOutcome!;
    }
  }

  Future<void> _refreshBalanceAndItems() async {
    try {
      final refreshed = await Future.wait<Object>([
        _credits.getBalance(),
        _generations.listGenerations(filter: filter, limit: 50),
      ]);
      balance = refreshed[0] as CreditBalance;
      items = refreshed[1] as List<GenerationItem>;
      notifyListeners();
    } catch (_) {
      // Mantido o estado de sucesso; o próximo `load(force: true)` corrige.
    }
  }

  /// Remove um item da galeria. Não estorna crédito (regra da E4a).
  Future<bool> delete(String id) async {
    try {
      await _generations.deleteGeneration(id);
      items = items.where((item) => item.id != id).toList();
      notifyListeners();
      return true;
    } catch (error) {
      errorMessage = _message(error);
      notifyListeners();
      return false;
    }
  }

  void clearFeedback() {
    errorMessage = null;
    insufficientBalance = false;
    generateState = GenerateState.idle;
    lastOutcome = null;
    lastGenerated = null;
    lastKind = null;
    notifyListeners();
  }

  String _message(Object error) => error is GenerationApiFailure
      ? error.message
      : 'Não foi possível concluir. Tente novamente.';
}
