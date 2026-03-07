import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';
import '../models/item_photo.dart';
import '../models/system.dart';
import '../models/system_detail.dart';
import 'home_profile_provider.dart';
import 'systems_provider.dart';

part 'system_detail_provider.g.dart';

/// Manages the full detail state for a single home system.
///
/// Keyed by [systemId] and auto-disposed when the detail screen is popped.
/// Fetches the system row plus all attached photos in parallel.
@riverpod
class SystemDetailNotifier extends _$SystemDetailNotifier {
  @override
  Future<SystemDetail> build(String systemId) => _fetchDetail(systemId);

  // ── Public interface ───────────────────────────────────────────────────────

  /// Updates system fields and re-fetches detail.
  Future<void> updateSystem(Map<String, dynamic> data) async {
    final detail = state.value;
    if (detail == null) throw StateError('System not loaded');

    await SupabaseService.client
        .from('systems')
        .update(data)
        .eq('id', detail.system.id);

    ref.invalidate(systemsProvider);
    ref.invalidate(homeProfileProvider);
    ref.invalidateSelf();
    await future;
  }

  /// Soft-deletes the system.
  Future<void> deleteSystem() async {
    final detail = state.value;
    if (detail == null) throw StateError('System not loaded');

    await SupabaseService.client
        .from('systems')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', detail.system.id);

    ref.invalidate(systemsProvider);
    ref.invalidate(homeProfileProvider);
  }

  /// Uploads a photo to `item-photos` and inserts an [item_photos] row.
  ///
  /// [photoType] must be one of: overview, model_label, location, condition,
  /// maintenance, other.
  Future<void> uploadPhoto(XFile photo, {String photoType = 'overview'}) async {
    final detail = state.value;
    if (detail == null) throw StateError('System not loaded');

    final user = SupabaseService.client.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');

    final bytes = await photo.readAsBytes();
    final ext = photo.name.split('.').last.toLowerCase();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${photo.name}';
    final path =
        '${user.id}/${detail.system.propertyId}/${detail.system.id}/$fileName';

    await SupabaseService.client.storage
        .from('item-photos')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: _mimeType(ext)),
        );

    await SupabaseService.client.from('item_photos').insert({
      'user_id': user.id,
      'system_id': detail.system.id,
      'file_path': path,
      'photo_type': photoType,
    });

    ref.invalidateSelf();
    await future;
  }

  /// Deletes a photo from storage and removes the [item_photos] row.
  Future<void> deletePhoto(String photoId, String filePath) async {
    await SupabaseService.client.storage
        .from('item-photos')
        .remove([filePath]);

    await SupabaseService.client
        .from('item_photos')
        .delete()
        .eq('id', photoId);

    ref.invalidateSelf();
    await future;
  }

  // ── Private fetch ──────────────────────────────────────────────────────────

  Future<SystemDetail> _fetchDetail(String systemId) async {
    final results = await Future.wait([
      SupabaseService.client
          .from('systems')
          .select(
            'id, property_id, user_id, category, system_type, name, status, '
            'brand, model, serial_number, installation_date, purchase_price, '
            'installer, location, expected_lifespan_min, expected_lifespan_max, '
            'lifespan_override, warranty_expiration, warranty_provider, '
            'estimated_replacement_cost, notes, created_at, updated_at',
          )
          .eq('id', systemId)
          .single(),
      SupabaseService.client
          .from('item_photos')
          .select(
            'id, user_id, system_id, appliance_id, file_path, thumbnail_path, '
            'photo_type, caption, created_at',
          )
          .eq('system_id', systemId)
          .order('created_at', ascending: false),
    ]);

    final systemRow = results[0] as Map<String, dynamic>;
    final photoRows = results[1] as List<dynamic>;

    final system = HomeSystem.fromJson(Map<String, dynamic>.from(systemRow));
    final photos = photoRows
        .map(
          (r) => ItemPhoto.fromJson(Map<String, dynamic>.from(r as Map)),
        )
        .toList();

    return SystemDetail(system: system, photos: photos);
  }

  static String _mimeType(String ext) => switch (ext) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'heic' => 'image/heic',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
}
