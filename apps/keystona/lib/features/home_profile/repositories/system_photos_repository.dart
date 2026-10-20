import 'package:image_picker/image_picker.dart';

import '../models/system_detail.dart';

/// A system's photos (`item_photos`, bucket `item-photos`): the summary the
/// detail hero needs, and uploads from the Add form.
abstract interface class SystemPhotosRepository {
  /// How many photos the system has and the picture to show on top.
  Future<SystemPhotoSummary> summary(String systemId);

  /// Uploads [photo] and links it to the system. [photoType] is the
  /// `photo_type` ("overview", "label").
  Future<void> upload(
    String systemId,
    XFile photo, {
    required String photoType,
  });
}
