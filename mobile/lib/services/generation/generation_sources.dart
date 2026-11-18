import 'generation_models.dart';

/// Origem dos dados de crédito. Implementação real usa a API gerada.
abstract class CreditSource {
  Future<CreditBalance> getBalance();
  Future<List<GenerationCost>> listCosts();
}

/// Origem das gerações. Implementação real usa a API gerada.
abstract class GenerationSource {
  Future<GenerationItem> generateImage({
    required String prompt,
    String? style,
    String? size,
    String? idempotencyKey,
  });

  Future<List<GenerationItem>> listGenerations({
    required GenerationFilter filter,
    int limit,
    int offset,
  });

  Future<void> deleteGeneration(String id);
}

/// Falha de comunicação já traduzida para a camada de apresentação.
class GenerationApiFailure implements Exception {
  const GenerationApiFailure({
    required this.message,
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  bool get isInsufficientBalance => statusCode == 402;
  bool get isUnavailable => statusCode == 503 || statusCode == 504 || statusCode == 502;

  @override
  String toString() => message;
}
