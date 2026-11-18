import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/generated/src/model/animate_photo_in.dart';
import '../api/generated/src/model/cost_config_out.dart';
import '../api/generated/src/model/generation_out.dart';
import '../api/generated/src/model/image_generation_in.dart';
import '../api/generated/src/model/upload_out.dart';
import '../api/generated/src/model/video_generation_in.dart';
import '../auth/auth_locator.dart';
import 'generation_models.dart';
import 'generation_sources.dart';

/// Função que fornece o ID token atual. Injetável para testes.
typedef TokenProvider = String? Function();

/// Implementação das fontes usando o cliente Dart gerado do OpenAPI.
///
/// O token é enviado em cada chamada, seguindo o mesmo padrão já usado na
/// sincronização de sessão (`auth_locator.dart`).
class ApiGenerationSource implements CreditSource, GenerationSource {
  ApiGenerationSource({
    ApiClient? api,
    TokenProvider? tokenProvider,
    String baseUrl = apiBaseUrl,
  })  : _api = api ?? ApiClient(baseUrl: baseUrl),
        _tokenProvider = tokenProvider ?? (() => authRepository.user?.idToken),
        _baseUrl = baseUrl;

  final ApiClient _api;
  final TokenProvider _tokenProvider;
  final String _baseUrl;

  Map<String, dynamic> get _headers {
    final token = _tokenProvider();
    if (token == null || token.isEmpty) return <String, dynamic>{};
    return <String, dynamic>{'Authorization': 'Bearer $token'};
  }

  @override
  Future<CreditBalance> getBalance() async {
    try {
      final response = await _api.credits.getCreditBalance(headers: _headers);
      final data = response.data;
      if (data == null) throw GenerationApiFailure(message: 'Resposta inválida do servidor.');
      return CreditBalance(
        balance: data.balance,
        reserved: data.reserved ?? 0,
        available: data.available,
      );
    } on DioException catch (error) {
      throw _translate(error);
    }
  }

  @override
  Future<List<GenerationCost>> listCosts() async {
    try {
      final response = await _api.credits.listCreditCosts(headers: _headers);
      return (response.data ?? const <CostConfigOut>[])
          .map(
            (item) => GenerationCost(
              operation: item.operation,
              credits: item.credits,
              enabled: item.enabled,
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw _translate(error);
    }
  }

  @override
  Future<GenerationItem> generateImage({
    required String prompt,
    String? style,
    String? size,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? _newKey();
    try {
      final response = await _api.generations.generateImage(
        imageGenerationIn: ImageGenerationIn((builder) => builder
          ..prompt = prompt
          ..style = style
          ..size = size
          ..idempotencyKey = key),
        headers: _headers,
      );
      final data = response.data;
      if (data == null) throw GenerationApiFailure(message: 'Resposta inválida do servidor.');
      return _map(data);
    } on DioException catch (error) {
      throw _translate(error);
    }
  }

  @override
  Future<GenerationItem> generateVideo({
    required String prompt,
    int? durationSeconds,
    String? resolution,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? _newKey();
    try {
      final response = await _api.generations.generateVideo(
        videoGenerationIn: VideoGenerationIn((builder) => builder
          ..prompt = prompt
          ..durationSeconds = durationSeconds
          ..resolution = resolution
          ..idempotencyKey = key),
        headers: _headers,
      );
      final data = response.data;
      if (data == null) throw GenerationApiFailure(message: 'Resposta inválida do servidor.');
      return _map(data);
    } on DioException catch (error) {
      throw _translate(error);
    }
  }

  @override
  Future<GenerationItem> animatePhoto({
    required String imageUrl,
    String? motion,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? _newKey();
    try {
      final response = await _api.generations.animatePhoto(
        animatePhotoIn: AnimatePhotoIn((builder) => builder
          ..imageUrl = imageUrl
          ..motion = motion
          ..idempotencyKey = key),
        headers: _headers,
      );
      final data = response.data;
      if (data == null) throw GenerationApiFailure(message: 'Resposta inválida do servidor.');
      return _map(data);
    } on DioException catch (error) {
      throw _translate(error);
    }
  }

  @override
  Future<GenerationItem> getGeneration(String id) async {
    try {
      final response = await _api.generations.getGeneration(
        generationId: id,
        headers: _headers,
      );
      final data = response.data;
      if (data == null) throw GenerationApiFailure(message: 'Resposta inválida do servidor.');
      return _map(data);
    } on DioException catch (error) {
      throw _translate(error);
    }
  }

  @override
  Future<String> uploadImage(
    Uint8List bytes, {
    required String fileName,
    required String mimeType,
  }) async {
    try {
      final response = await _api.generations.uploadGenerationImage(
        file: MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: DioMediaType.parse(mimeType),
        ),
        headers: _headers,
      );
      final data = response.data;
      if (data is! UploadOut) {
        throw GenerationApiFailure(message: 'Resposta inválida do servidor.');
      }
      return _absoluteUrl(data.imageUrl);
    } on DioException catch (error) {
      throw _translate(error);
    }
  }

  @override
  Future<List<GenerationItem>> listGenerations({
    required GenerationFilter filter,
    int limit = 50,
    int offset = 0,
  }) async {
    final type = filter.backendType;
    if (type == null) return const <GenerationItem>[];
    try {
      final response = await _api.generations.listGenerations(
        limit: limit,
        offset: offset,
        type: type,
        headers: _headers,
      );
      return (response.data ?? const <GenerationOut>[]).map(_map).toList();
    } on DioException catch (error) {
      throw _translate(error);
    }
  }

  @override
  Future<void> deleteGeneration(String id) async {
    try {
      await _api.generations.deleteGeneration(
        generationId: id,
        headers: _headers,
      );
    } on DioException catch (error) {
      throw _translate(error);
    }
  }

  GenerationItem _map(GenerationOut item) {
    final rawUrl = item.mediaUrl;
    return GenerationItem(
      id: item.id,
      type: item.type,
      status: item.status,
      costCredits: item.costCredits,
      createdAt: item.createdAt,
      prompt: item.prompt,
      mediaUrl: rawUrl == null ? null : _absoluteUrl(rawUrl),
      errorMessage: item.errorMessage,
      progress: item.progress ?? 0,
    );
  }

  String _absoluteUrl(String url) {
    final parsed = Uri.tryParse(url);
    if (parsed != null && parsed.hasScheme) return url;
    return Uri.parse(_baseUrl).resolve(url).toString();
  }

  String _newKey() {
    final random = Random();
    final suffix = random.nextInt(1 << 30).toRadixString(16);
    return '${DateTime.now().microsecondsSinceEpoch}-$suffix';
  }

  GenerationApiFailure _translate(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;

    if (status == 402) {
      return const GenerationApiFailure(
        message: 'Seus créditos acabaram. Escolha um plano para continuar criando.',
        statusCode: 402,
      );
    }
    if (status == 503) {
      return const GenerationApiFailure(
        message: 'A geração está temporariamente indisponível. Tente novamente em instantes.',
        statusCode: 503,
      );
    }
    if (status == 504) {
      return const GenerationApiFailure(
        message: 'A geração demorou mais do que o esperado. Seus créditos foram devolvidos.',
        statusCode: 504,
      );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const GenerationApiFailure(
          message: 'A conexão demorou mais do que o esperado. Tente novamente.',
        );
      case DioExceptionType.connectionError:
        return const GenerationApiFailure(
          message: 'Não foi possível conectar ao servidor. Verifique sua conexão.',
        );
      default:
        break;
    }

    String? detail;
    if (data is Map && data['detail'] is String) {
      detail = data['detail'] as String;
    } else if (data is String && data.isNotEmpty) {
      detail = data;
    }
    return GenerationApiFailure(
      message: detail ?? 'Não foi possível concluir. Tente novamente.',
      statusCode: status,
    );
  }
}
