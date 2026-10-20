import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../models/item_photo.dart';
import '../models/item_photo_type.dart';
import '../models/item_photos_state.dart';
import '../models/item_ref.dart';
import '../repositories/item_photos_repository.dart';
import '../repositories/supabase_item_photos_repository.dart';

part 'item_photos_provider.g.dart';

/// The data source behind the photo screens. Tests override it.
final itemPhotosRepositoryProvider = Provider<ItemPhotosRepository>(
  (ref) => SupabaseItemPhotosRepository(SupabaseService.client),
);

/// A system's or appliance's photos with their signed links, plus adding and
/// deleting. Auto-disposed with the screens that watch it.
///
/// Deleting is optimistic (the photo leaves at once, a failed write puts it
/// back and rethrows); adding waits for the upload so the photo has its id.
@riverpod
class ItemPhotosNotifier extends _$ItemPhotosNotifier {
  @override
  Future<ItemPhotos> build(ItemRef item) async {
    final repository = ref.read(itemPhotosRepositoryProvider);
    final photos = await repository.list(item);
    final urls = await repository.signedUrls(photos);
    return ItemPhotos(photos: photos, urls: urls);
  }

  ItemPhotosRepository get _repository =>
      ref.read(itemPhotosRepositoryProvider);

  /// Uploads [file] as a [type] photo and returns it.
  Future<ItemPhoto> add(
    XFile file,
    ItemPhotoType type, {
    String? caption,
  }) async {
    final photo = await _repository.add(item, file, type, caption: caption);
    final urls = await _repository.signedUrls([photo]);
    final current = state.value ?? const ItemPhotos();
    state = AsyncData(current.plus(photo, urls[photo.filePath]));
    return photo;
  }

  /// Deletes [photo] from the item.
  Future<void> remove(ItemPhoto photo) async {
    final before = state.value;
    if (before == null) return;
    state = AsyncData(before.without(photo.id));
    try {
      await _repository.delete(photo);
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
  }
}
