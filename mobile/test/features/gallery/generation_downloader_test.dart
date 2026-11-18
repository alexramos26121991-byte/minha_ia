import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minha_ia/services/generation/generation_downloader.dart';

import '../generation/fakes.dart';

class _BytesAdapter implements HttpClientAdapter {
  const _BytesAdapter(this.bytes);

  final List<int> bytes;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromBytes(bytes, 200);

  @override
  void close({bool force = false}) {}
}

void main() {
  test('baixa a mídia e salva no diretório informado', () async {
    final directory = await Directory.systemTemp.createTemp('minha-ia-download-');
    final dio = Dio()..httpClientAdapter = const _BytesAdapter(<int>[1, 2, 3]);
    final downloader = GenerationDownloader(
      dio: dio,
      directory: () async => directory,
    );

    final path = await downloader.download(fakeItem());
    final file = File(path);

    expect(await file.exists(), isTrue);
    expect(await file.readAsBytes(), <int>[1, 2, 3]);
    dio.close();
    await directory.delete(recursive: true);
  });

  test('recusa item sem URL de mídia', () async {
    const downloader = GenerationDownloader();

    expect(
      () => downloader.download(fakeItem(mediaUrl: null)),
      throwsA(isA<GenerationDownloadFailure>()),
    );
  });
}
