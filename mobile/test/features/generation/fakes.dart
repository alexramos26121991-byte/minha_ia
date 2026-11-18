import 'package:minha_ia/services/generation/generation_models.dart';
import 'package:minha_ia/services/generation/generation_sources.dart';

/// Fontes falsas para testes: sem rede, sem persistência, determinísticas.
class FakeCreditSource implements CreditSource {
  FakeCreditSource({
    CreditBalance? balance,
    List<GenerationCost>? costs,
    this.balanceError,
    this.costsError,
  })  : balance = balance ??
            const CreditBalance(balance: 42, reserved: 0, available: 42),
        costs = costs ??
            const <GenerationCost>[
              GenerationCost(operation: 'image', credits: 10, enabled: true),
            ];

  CreditBalance balance;
  List<GenerationCost> costs;
  Object? balanceError;
  Object? costsError;

  int balanceCalls = 0;
  int costsCalls = 0;

  @override
  Future<CreditBalance> getBalance() async {
    balanceCalls++;
    if (balanceError != null) throw balanceError!;
    return balance;
  }

  @override
  Future<List<GenerationCost>> listCosts() async {
    costsCalls++;
    if (costsError != null) throw costsError!;
    return costs;
  }
}

class FakeGenerationSource implements GenerationSource {
  FakeGenerationSource({
    List<GenerationItem>? items,
    this.generateResult,
    this.generateError,
    this.listError,
    this.deleteError,
  }) : items = items ?? const <GenerationItem>[];

  List<GenerationItem> items;
  GenerationItem? generateResult;
  Object? generateError;
  Object? listError;
  Object? deleteError;

  int generateCalls = 0;
  int listCalls = 0;
  GenerationFilter? lastFilter;
  final List<String> deletedIds = <String>[];

  @override
  Future<GenerationItem> generateImage({
    required String prompt,
    String? style,
    String? size,
    String? idempotencyKey,
  }) async {
    generateCalls++;
    if (generateError != null) throw generateError!;
    final item = generateResult ?? fakeItem(prompt: prompt);
    items = <GenerationItem>[item, ...items];
    return item;
  }

  @override
  Future<List<GenerationItem>> listGenerations({
    required GenerationFilter filter,
    int limit = 50,
    int offset = 0,
  }) async {
    listCalls++;
    lastFilter = filter;
    if (listError != null) throw listError!;
    if (!filter.hasBackendData) return const <GenerationItem>[];
    return items
        .where(
          (item) => filter == GenerationFilter.videos
              ? item.isVideo
              : !item.isVideo,
        )
        .toList();
  }

  @override
  Future<void> deleteGeneration(String id) async {
    if (deleteError != null) throw deleteError!;
    deletedIds.add(id);
    items = items.where((item) => item.id != id).toList();
  }
}

GenerationItem fakeItem({
  String id = 'gen-1',
  String prompt = 'um gato astronauta em uma galáxia colorida',
  bool isVideo = false,
  String status = 'completed',
  String? mediaUrl = 'http://localhost:8000/media/gen-1.png',
}) =>
    GenerationItem(
      id: id,
      type: isVideo ? 'video' : 'image',
      status: status,
      costCredits: 10,
      createdAt: DateTime(2026, 1, 1),
      prompt: prompt,
      mediaUrl: mediaUrl,
    );
