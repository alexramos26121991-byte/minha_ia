import 'dart:typed_data';

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
              GenerationCost(operation: 'video', credits: 50, enabled: true),
              GenerationCost(operation: 'animate_photo', credits: 20, enabled: true),
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
    this.generateVideoResult,
    this.generateVideoError,
    this.animatePhotoResult,
    this.animatePhotoError,
    List<GenerationItem>? generationResults,
    this.getGenerationError,
    this.uploadUrl = 'http://localhost:8000/media/upload.png',
    this.uploadError,
    this.listError,
    this.deleteError,
  })  : items = items ?? const <GenerationItem>[],
        generationResults = generationResults ?? const <GenerationItem>[];

  List<GenerationItem> items;
  GenerationItem? generateResult;
  Object? generateError;
  GenerationItem? generateVideoResult;
  Object? generateVideoError;
  GenerationItem? animatePhotoResult;
  Object? animatePhotoError;

  /// Respostas sucessivas de `getGeneration` (polling). A última se repete.
  List<GenerationItem> generationResults;
  Object? getGenerationError;

  String uploadUrl;
  Object? uploadError;

  Object? listError;
  Object? deleteError;

  int generateCalls = 0;
  int generateVideoCalls = 0;
  int animatePhotoCalls = 0;
  int getGenerationCalls = 0;
  int uploadCalls = 0;
  int listCalls = 0;

  GenerationFilter? lastFilter;
  final List<String> deletedIds = <String>[];
  final List<String> generationQueries = <String>[];

  String? lastVideoPrompt;
  int? lastDurationSeconds;
  String? lastResolution;
  String? lastImageUrl;
  String? lastMotion;
  Uint8List? lastUploadBytes;
  String? lastUploadFileName;
  String? lastUploadMimeType;

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
  Future<GenerationItem> generateVideo({
    required String prompt,
    int? durationSeconds,
    String? resolution,
    String? idempotencyKey,
  }) async {
    generateVideoCalls++;
    lastVideoPrompt = prompt;
    lastDurationSeconds = durationSeconds;
    lastResolution = resolution;
    if (generateVideoError != null) throw generateVideoError!;
    final item = generateVideoResult ??
        fakeItem(
          id: 'video-1',
          prompt: prompt,
          isVideo: true,
          status: 'queued',
          mediaUrl: null,
        );
    items = <GenerationItem>[item, ...items];
    return item;
  }

  @override
  Future<GenerationItem> animatePhoto({
    required String imageUrl,
    String? motion,
    String? idempotencyKey,
  }) async {
    animatePhotoCalls++;
    lastImageUrl = imageUrl;
    lastMotion = motion;
    if (animatePhotoError != null) throw animatePhotoError!;
    final item = animatePhotoResult ??
        fakeItem(
          id: 'animate-1',
          type: 'animate_photo',
          prompt: imageUrl,
          isVideo: true,
          status: 'queued',
          mediaUrl: null,
        );
    items = <GenerationItem>[item, ...items];
    return item;
  }

  @override
  Future<GenerationItem> getGeneration(String id) async {
    getGenerationCalls++;
    generationQueries.add(id);
    if (getGenerationError != null) throw getGenerationError!;
    if (generationResults.isEmpty) {
      return fakeItem(
        id: id,
        isVideo: true,
        status: 'completed',
        mediaUrl: 'http://localhost:8000/media/$id.mp4',
      );
    }
    final index = (getGenerationCalls - 1).clamp(0, generationResults.length - 1);
    return generationResults[index];
  }

  @override
  Future<String> uploadImage(
    Uint8List bytes, {
    required String fileName,
    required String mimeType,
  }) async {
    uploadCalls++;
    lastUploadBytes = bytes;
    lastUploadFileName = fileName;
    lastUploadMimeType = mimeType;
    if (uploadError != null) throw uploadError!;
    return uploadUrl;
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
  String? type,
  String status = 'completed',
  String? mediaUrl = 'http://localhost:8000/media/gen-1.png',
  int costCredits = 10,
  int progress = 100,
  String? errorMessage,
}) =>
    GenerationItem(
      id: id,
      type: type ?? (isVideo ? 'video' : 'image'),
      status: status,
      costCredits: costCredits,
      createdAt: DateTime(2026, 1, 1),
      prompt: prompt,
      mediaUrl: mediaUrl,
      progress: progress,
      errorMessage: errorMessage,
    );
