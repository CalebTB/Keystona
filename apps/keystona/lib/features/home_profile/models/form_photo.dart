import 'package:image_picker/image_picker.dart';

import 'item_photo_type.dart';

/// A photo picked in the Add form, kept on the device until the appliance is
/// saved.
class FormPhoto {
  const FormPhoto(this.file, this.type);

  final XFile file;
  final ItemPhotoType type;
}
