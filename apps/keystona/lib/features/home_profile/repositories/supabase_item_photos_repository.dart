import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../documents/repositories/current_property.dart';
import '../models/item_photo.dart';
import '../models/item_photo_type.dart';
import '../models/item_ref.dart';
import 'item_photos_repository.dart';

/// [ItemPhotosRepository] on Supabase. A photo belongs to exactly one of a
/// system or an appliance.
class SupabaseItemPhotosRepository implements ItemPhotosRepository {
  const SupabaseItemPhotosRepository(this._client);

  final SupabaseClient _client;

  static const String bucket = 'item-photos';
  static const String columns =
      'id, user_id, system_id, appliance_id, file_path, thumbnail_path, '
      'photo_type, caption, created_at';

  /// How long a signed link lasts, in seconds.
  static const int signedUrlSeconds = 3600;

  static String _column(ItemRef item) =>
      item.isSystem ? 'system_id' : 'appliance_id';

  @override
  Future<List<ItemPhoto>> list(ItemRef item) async {
    final rows = await _client
        .from('item_photos')
        .select(columns)
        .eq(_column(item), item.id)
        .order('created_at');
    return rows.map(ItemPhoto.fromJson).toList();
  }

  @override
  Future<Map<String, String>> signedUrls(List<ItemPhoto> photos) async {
    final urls = <String, String>{};
    await Future.wait([
      for (final p in photos)
        () async {
          try {
            urls[p.filePath] = await _client.storage
                .from(bucket)
                .createSignedUrl(p.filePath, signedUrlSeconds);
          } catch (_) {
            // The tile shows the grid placeholder instead.
          }
        }(),
    ]);
    return urls;
  }

  @override
  Future<ItemPhoto> add(
    ItemRef item,
    XFile file,
    ItemPhotoType type, {
    String? caption,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');
    final propertyId = await currentPropertyId(_client);
    if (propertyId == null) throw StateError('No property found');
    final bytes = await file.readAsBytes();
    final ext = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : 'jpg';
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${user.id}/$propertyId/${item.id}/${stamp}_${type.value}.$ext';
    await _client.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: _mime(ext)),
        );
    final row = await _client
        .from('item_photos')
        .insert({
          'user_id': user.id,
          _column(item): item.id,
          'file_path': path,
          'photo_type': type.value,
          'caption': ?caption,
        })
        .select(columns)
        .single();
    return ItemPhoto.fromJson(row);
  }

  @override
  Future<void> delete(ItemPhoto photo) async {
    await _client.from('item_photos').delete().eq('id', photo.id);
    try {
      await _client.storage.from(bucket).remove([photo.filePath]);
    } catch (_) {
      // The row is gone; a stray file does no harm.
    }
  }

  static String _mime(String ext) => switch (ext) {
    'png' => 'image/png',
    'heic' => 'image/heic',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };
}
