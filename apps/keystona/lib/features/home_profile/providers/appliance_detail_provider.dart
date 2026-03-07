import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../models/appliance.dart';
import '../models/appliance_detail.dart';
import '../models/item_photo.dart';
import 'appliances_provider.dart';
import 'home_profile_provider.dart';

part 'appliance_detail_provider.g.dart';

const _kApplianceColumns =
    'id, property_id, user_id, category, name, status, brand, model, '
    'serial_number, purchase_date, warranty_expiration, purchase_price, '
    'location, color, lifespan_override, warranty_provider, '
    'linked_warranty_doc_id, notes, estimated_replacement_cost, '
    'created_at, updated_at';

const _kPhotoColumns =
    'id, user_id, appliance_id, file_path, thumbnail_path, '
    'photo_type, caption, created_at';

@riverpod
class ApplianceDetailNotifier extends _$ApplianceDetailNotifier {
  @override
  Future<ApplianceDetail> build(String applianceId) =>
      _fetchDetail(applianceId);

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchDetail(applianceId));
  }

  Future<void> updateAppliance(Map<String, dynamic> fields) async {
    await SupabaseService.client
        .from('appliances')
        .update({...fields, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', applianceId);
    ref.invalidate(appliancesProvider);
    ref.invalidateSelf();
    await future;
  }

  Future<void> uploadPhoto(
    File file,
    String photoType, {
    String? caption,
  }) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final propertyRow = await SupabaseService.client
        .from('properties')
        .select('id')
        .eq('user_id', user.id)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (propertyRow == null) throw Exception('No property found');
    final propertyId = propertyRow['id'] as String;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath =
        '${user.id}/$propertyId/appliances/$applianceId/$timestamp.jpg';
    await SupabaseService.client.storage
        .from('item-photos')
        .upload(filePath, file);
    await SupabaseService.client.from('item_photos').insert({
      'user_id': user.id,
      'appliance_id': applianceId,
      'file_path': filePath,
      'photo_type': photoType,
      'caption': caption,
    });
    ref.invalidateSelf();
    await future;
  }

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

  Future<void> softDelete() async {
    await SupabaseService.client
        .from('appliances')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', applianceId);
    ref.invalidate(appliancesProvider);
    ref.invalidate(homeProfileProvider);
  }

  Future<ApplianceDetail> _fetchDetail(String id) async {
    final row = await SupabaseService.client
        .from('appliances')
        .select('$_kApplianceColumns, photos:item_photos($_kPhotoColumns)')
        .eq('id', id)
        .single();
    final appliance = Appliance.fromJson(row);
    final photoRows =
        (row['photos'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final photos = photoRows.map(ItemPhoto.fromJson).toList();
    return ApplianceDetail(appliance: appliance, photos: photos);
  }
}
