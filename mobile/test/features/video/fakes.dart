import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:minha_ia/services/generation/generation_downloader.dart';
import 'package:minha_ia/services/generation/generation_models.dart';
import 'package:minha_ia/services/generation/image_source.dart';
import 'package:minha_ia/services/notifications/notification_service.dart';

/// Seleciona uma imagem determinística, sem abrir a galeria do dispositivo.
class FakeImagePicker implements ImagePickerPort {
  FakeImagePicker({this.picked, this.error});

  final PickedImage? picked;
  final Object? error;

  int calls = 0;

  @override
  Future<PickedImage?> pickImage() async {
    calls++;
    if (error != null) throw error!;
    return picked;
  }
}

/// Canal de push falso: permite disparar eventos sem Firebase.
class FakeNotificationService implements NotificationService {
  final StreamController<GenerationNotification> _controller =
      StreamController<GenerationNotification>.broadcast();

  int initializeCalls = 0;
  bool disposed = false;

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  Future<String?> getToken() async => 'fake-token';

  @override
  Stream<GenerationNotification> get generations => _controller.stream;

  @override
  Future<void> dispose() async {
    disposed = true;
    await _controller.close();
  }

  void emit(String generationId, String status) {
    _controller.add(
      GenerationNotification(generationId: generationId, status: status),
    );
  }
}

/// Adapter HTTP que devolve bytes fixos para os testes do downloader.
class BytesHttpAdapter implements HttpClientAdapter {
  BytesHttpAdapter({
    this.bytes = const <int>[1, 2, 3, 4],
    this.statusCode = 200,
    this.error,
  });

  final List<int> bytes;
  final int statusCode;
  final Object? error;

  final List<String> requestedUrls = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestedUrls.add(options.uri.toString());
    if (error != null) throw error!;
    return ResponseBody.fromBytes(bytes, statusCode);
  }

  @override
  void close({bool force = false}) {}
}

/// Evita I/O de disco dentro da zona de teste de widgets.
class FakeGenerationDownloader implements GenerationDownloader {
  FakeGenerationDownloader(this.path);

  final String path;
  GenerationItem? downloaded;

  @override
  Future<String> download(GenerationItem item) async {
    downloaded = item;
    return path;
  }
}

PickedImage fakePickedImage() => PickedImage(
      bytes: Uint8List.fromList(const <int>[137, 80, 78, 71]),
      fileName: 'foto.png',
      mimeType: 'image/png',
    );
