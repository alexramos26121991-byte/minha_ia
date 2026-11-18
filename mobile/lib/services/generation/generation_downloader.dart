import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'generation_models.dart';

/// Baixa a mídia gerada para o dispositivo.
///
/// O diretório é injetável para que os testes não dependam de permissões.
class GenerationDownloader {
  const GenerationDownloader({
    Dio? dio,
    Future<Directory> Function()? directory,
  })  : _dio = dio,
        _directory = directory;

  final Dio? _dio;
  final Future<Directory> Function()? _directory;

  Future<String> download(GenerationItem item) async {
    final url = item.mediaUrl;
    if (url == null || url.isEmpty) {
      throw const GenerationDownloadFailure('Esta imagem ainda não pode ser baixada.');
    }

    final dio = _dio ?? Dio();
    late final List<int> bytes;
    try {
      final response = await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      bytes = response.data ?? const <int>[];
    } on DioException catch (_) {
      throw const GenerationDownloadFailure(
        'Não foi possível baixar a imagem. Verifique sua conexão.',
      );
    }

    if (bytes.isEmpty) {
      throw const GenerationDownloadFailure('O arquivo baixado está vazio.');
    }

    try {
      final directory = _directory != null
          ? await _directory()
          : await getApplicationDocumentsDirectory();
      final file = File('${directory.path}${Platform.pathSeparator}${item.id}.png');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } on FileSystemException catch (_) {
      throw const GenerationDownloadFailure(
        'Não foi possível salvar a imagem no dispositivo.',
      );
    }
  }
}

class GenerationDownloadFailure implements Exception {
  const GenerationDownloadFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
