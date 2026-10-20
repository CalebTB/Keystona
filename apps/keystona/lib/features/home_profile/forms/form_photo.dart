import 'package:image_picker/image_picker.dart';

/// A photo chosen on the Add form, uploaded after Save.
class FormPhoto {
  const FormPhoto({required this.file, this.isLabel = false});

  final XFile file;

  /// The scanned label picture: saved as the item's LABEL photo.
  final bool isLabel;

  /// The `photo_type` it is saved with.
  String get photoType => isLabel ? 'label' : 'overview';
}
