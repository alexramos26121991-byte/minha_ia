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
    final noun = item.isVideo ? 'vídeo' : 'imagem';
    if (url == null || url.isEmpty) {
      throw GenerationDownloadFailure('Este $noun ainda não pode ser baixado.');
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
      throw GenerationDownloadFailure(
        'Não foi possível baixar o $noun. Verifique sua conexão.',
      );
    }

    if (bytes.isEmpty) {
      throw const GenerationDownloadFailure('O arquivo baixado está vazio.');
    }

    try {
      final directory = _directory != null
          ? await _directory()
          : await getApplicationDocumentsDirectory();
      final extension = item.isVideo ? 'mp4' : 'png';
      final file = File(
        '${directory.path}${Platform.pathSeparator}${item.id}.$extension',
      );
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } on FileSystemException catch (_) {
      throw GenerationDownloadFailure(
        'Não foi possível salvar o $noun no dispositivo.',
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
