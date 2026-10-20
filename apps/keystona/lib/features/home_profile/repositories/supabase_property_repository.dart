import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/property.dart';
import '../models/property_edits.dart';
import 'property_repository.dart';

/// [PropertyRepository] over Supabase. The `property-photos` bucket is public
/// today; cover photos are still read through signed URLs.
class SupabasePropertyRepository implements PropertyRepository {
  const SupabasePropertyRepository(this._client);

  final SupabaseClient _client;

  static const String _bucket = 'property-photos';

  /// Signed URL lifetime, in seconds.
  static const int _signedSeconds = 3600;

  static const String _columns =
      'id, user_id, address_line1, address_line2, city, state, zip_code, '
      'property_type, year_built, square_feet, lot_size_sqft, bedrooms, '
      'bathrooms, stories, has_basement, garage_type, garage_spaces, '
      'purchase_date, purchase_price, climate_zone, exterior_photo_path, '
      'created_at, updated_at';

  @override
  Future<Property?> fetchProperty() async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');
    final row = await _client
        .from('properties')
        .select(_columns)
        .eq('user_id', user.id)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : Property.fromJson(row);
  }

  @override
  Future<String?> signedPhotoUrl(String path) async {
    try {
      return await _client.storage
          .from(_bucket)
          .createSignedUrl(path, _signedSeconds);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(String propertyId, PropertyEdits edits) async {
    String? photoPath;
    final photo = edits.newPhoto;
    final user = _client.auth.currentUser;
    if (photo != null && user != null) {
      final extension = photo.path.split('.').last;
      photoPath = '${user.id}/${const Uuid().v4()}.$extension';
      await _client.storage.from(_bucket).upload(photoPath, photo);
    }
    await _client
        .from('properties')
        .update(edits.toColumns(photoPath: photoPath))
        .eq('id', propertyId);
  }
}
