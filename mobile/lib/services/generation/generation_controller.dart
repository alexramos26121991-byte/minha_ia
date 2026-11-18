import 'package:flutter/foundation.dart';

import 'generation_models.dart';
import 'generation_sources.dart';

/// Estado da carga inicial (saldo + custos).
enum GenerationLoadState { initial, loading, ready, error }

/// Resultado da última tentativa de geração.
enum GenerateState { idle, generating, success, error }

/// Desfecho de `generateImage`, usado pela UI para escolher a mensagem.
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

  CreditBalance? balance;
  List<GenerationCost> costs = const <GenerationCost>[];
  List<GenerationItem> items = const <GenerationItem>[];
  GenerationFilter filter = GenerationFilter.images;
  GenerationItem? lastGenerated;

  /// Custo real da geração de imagem, vindo do backend.
  int get imageCost {
    for (final cost in costs) {
      if (cost.operation == 'image' && cost.enabled) return cost.credits;
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
  }) async {
    final text = prompt.trim();
    if (text.isEmpty) {
      errorMessage = 'Descreva o que você quer criar.';
      insufficientBalance = false;
      lastOutcome = GenerateOutcome.error;
      generateState = GenerateState.error;
      notifyListeners();
      return GenerateOutcome.error;
    }

    final cost = imageCost;
    final available = balance?.available;
    if (cost > 0 && available != null && available < cost) {
      errorMessage = 'Saldo insuficiente: esta criação custa $cost créditos.';
      insufficientBalance = true;
      lastOutcome = GenerateOutcome.insufficientBalance;
      generateState = GenerateState.error;
      notifyListeners();
      return GenerateOutcome.insufficientBalance;
    }

    generateState = GenerateState.generating;
    errorMessage = null;
    insufficientBalance = false;
    lastGenerated = null;
    lastOutcome = null;
    notifyListeners();

    try {
      final item = await _generations.generateImage(
        prompt: text,
        style: style,
        size: size,
      );
      lastGenerated = item;
      generateState = GenerateState.success;
      lastOutcome = GenerateOutcome.success;
      notifyListeners();

      // Atualiza saldo e galeria em segundo plano: uma falha aqui não desfaz
      // uma geração que o backend já entregou.
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
    notifyListeners();
  }

  String _message(Object error) => error is GenerationApiFailure
      ? error.message
      : 'Não foi possível concluir. Tente novamente.';
}
