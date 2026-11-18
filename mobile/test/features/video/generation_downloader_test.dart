import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minha_ia/services/generation/generation_downloader.dart';

import '../generation/fakes.dart';
import 'fakes.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('minha_ia_download_');
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  GenerationDownloader downloader(BytesHttpAdapter adapter) =>
      GenerationDownloader(
        dio: Dio()..httpClientAdapter = adapter,
        directory: () async => directory,
      );

  test('vídeo é salvo com extensão .mp4', () async {
    final bytes = Uint8List.fromList(const <int>[1, 2, 3, 4]);
    final adapter = BytesHttpAdapter(bytes: bytes);
    final item = fakeItem(
      id: 'video-1',
      isVideo: true,
      mediaUrl: 'https://storage.example.com/video-1',
    );

    final path = await downloader(adapter).download(item);

    expect(path, endsWith('video-1.mp4'));
    final file = File(path);
    expect(await file.exists(), isTrue);
    expect(await file.readAsBytes(), bytes);
    expect(adapter.requestedUrls, <String>['https://storage.example.com/video-1']);
  });

  test('imagem é salva com extensão .png', () async {
    final item = fakeItem(mediaUrl: 'https://storage.example.com/gen-1');
    final path = await downloader(BytesHttpAdapter()).download(item);
    expect(path, endsWith('gen-1.png'));
  });

  test('item sem mídia disponível falha com mensagem específica', () async {
    final item = fakeItem(isVideo: true, mediaUrl: null);

    expect(
      () => downloader(BytesHttpAdapter()).download(item),
      throwsA(
        isA<GenerationDownloadFailure>().having(
          (error) => error.message,
          'message',
          contains('vídeo'),
        ),
      ),
    );
  });

  test('arquivo vazio é recusado', () async {
    final item = fakeItem(mediaUrl: 'https://storage.example.com/vazio');

    expect(
      () => downloader(BytesHttpAdapter(bytes: const <int>[])).download(item),
      throwsA(isA<GenerationDownloadFailure>()),
    );
  });

  test('erro de rede é traduzido para o usuário', () async {
    final item = fakeItem(mediaUrl: 'https://storage.example.com/erro');
    final adapter = BytesHttpAdapter(error: const SocketException('offline'));

    expect(
      () => downloader(adapter).download(item),
      throwsA(
        isA<GenerationDownloadFailure>().having(
          (error) => error.message,
          'message',
          contains('conexão'),
        ),
      ),
    );
  });
}
