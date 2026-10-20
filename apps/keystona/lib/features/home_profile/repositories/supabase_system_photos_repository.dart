import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';
import '../models/system_detail.dart';
import 'system_photos_repository.dart';

/// [SystemPhotosRepository] backed by Supabase.
class SupabaseSystemPhotosRepository implements SystemPhotosRepository {
  const SupabaseSystemPhotosRepository();

  static const String _bucket = 'item-photos';

  /// Signed URLs last this long, in seconds.
  static const int _signedUrlSeconds = 3600;

  /// The photo type shown on the hero when the system has one.
  static const String _heroType = 'overview';

  @override
  Future<SystemPhotoSummary> summary(String systemId) async {
    final rows = await SupabaseService.client
        .from('item_photos')
        .select('id, file_path, photo_type')
        .eq('system_id', systemId)
        .order('created_at', ascending: false);
    if (rows.isEmpty) return SystemPhotoSummary.none;
    final hero = rows.firstWhere(
      (r) => r['photo_type'] == _heroType,
      orElse: () => rows.first,
    );
    String? url;
    try {
      url = await SupabaseService.client.storage
          .from(_bucket)
          .createSignedUrl(hero['file_path'] as String, _signedUrlSeconds);
    } catch (_) {
      url = null;
    }
    return SystemPhotoSummary(
      count: rows.length,
      heroUrl: url,
      heroType: hero['photo_type'] as String?,
    );
  }

  @override
  Future<void> upload(
    String systemId,
    XFile photo, {
    required String photoType,
  }) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');
    final property = await SupabaseService.client
        .from('properties')
        .select('id')
        .eq('user_id', user.id)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    final propertyId = property?['id'] as String?;
    if (propertyId == null) throw StateError('No property found');

    final bytes = await photo.readAsBytes();
    final ext = photo.name.split('.').last.toLowerCase();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${user.id}/$propertyId/$systemId/${stamp}_$photoType.$ext';
    await SupabaseService.client.storage
        .from(_bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: _mimeType(ext)),
        );
    await SupabaseService.client.from('item_photos').insert({
      'user_id': user.id,
      'system_id': systemId,
      'file_path': path,
      'photo_type': photoType,
    });
  }

  static String _mimeType(String ext) => switch (ext) {
    'png' => 'image/png',
    'heic' => 'image/heic',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };
}
