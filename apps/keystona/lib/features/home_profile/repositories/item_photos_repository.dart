import 'package:image_picker/image_picker.dart';

import '../models/item_photo.dart';
import '../models/item_photo_type.dart';
import '../models/item_ref.dart';

/// Reads and writes the photos of a system or appliance (`item_photos` rows
/// and the private `item-photos` bucket).
abstract interface class ItemPhotosRepository {
  /// The item's photos, oldest first.
  Future<List<ItemPhoto>> list(ItemRef item);

  /// Signed links for [photos], keyed by file path. Made in parallel; a photo
  /// whose link fails is left out.
  Future<Map<String, String>> signedUrls(List<ItemPhoto> photos);

  /// Uploads [file] and adds its row. Returns the new photo.
  Future<ItemPhoto> add(
    ItemRef item,
    XFile file,
    ItemPhotoType type, {
    String? caption,
  });

  /// Deletes the row, then the stored file (best effort).
  Future<void> delete(ItemPhoto photo);
}
