import 'package:image_picker/image_picker.dart';

import 'image_source.dart';

/// Implementação real usando `image_picker`. O backend valida MIME e magic
/// bytes novamente, mesmo depois desta checagem superficial.
class ImagePickerAdapter implements ImagePickerPort {
  ImagePickerAdapter({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<PickedImage?> pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2048,
    );
    if (file == null) return null;
    return PickedImage(
      bytes: await file.readAsBytes(),
      fileName: file.name.isEmpty ? 'foto.png' : file.name,
      mimeType: _mimeFromName(file.name),
    );
  }

  String _mimeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/png';
  }
}
