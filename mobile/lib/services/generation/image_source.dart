import 'dart:typed_data';

/// Imagem escolhida pelo usuário, independente de plugin (facilita testes).
class PickedImage {
  const PickedImage({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
}

/// Seleção de imagem injetável na tela de animação.
abstract class ImagePickerPort {
  Future<PickedImage?> pickImage();
}
