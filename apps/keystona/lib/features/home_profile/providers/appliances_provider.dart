import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../models/appliance.dart';
import 'home_profile_provider.dart';

part 'appliances_provider.g.dart';

const _kColumns =
    'id, property_id, user_id, category, name, status, brand, model, '
    'serial_number, purchase_date, warranty_expiration, purchase_price, '
    'location, color, lifespan_override, warranty_provider, '
    'linked_warranty_doc_id, notes, estimated_replacement_cost, '
    'created_at, updated_at';

@riverpod
class AppliancesNotifier extends _$AppliancesNotifier {
  @override
  Future<List<Appliance>> build() => _fetchAppliances();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchAppliances);
  }

  Future<String> addAppliance(Map<String, dynamic> fields) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final propertyId = await _resolvePropertyId(user.id);
    final row = await SupabaseService.client
        .from('appliances')
        .insert({...fields, 'user_id': user.id, 'property_id': propertyId})
        .select('id')
        .single();
    ref.invalidate(homeProfileProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchAppliances);
    return row['id'] as String;
  }

  Future<void> updateAppliance(String id, Map<String, dynamic> fields) async {
    await SupabaseService.client
        .from('appliances')
        .update({...fields, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchAppliances);
  }

  Future<void> softDelete(String id) async {
    await SupabaseService.client
        .from('appliances')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
    ref.invalidate(homeProfileProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchAppliances);
  }

  Future<List<Appliance>> _fetchAppliances() async {
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
    if (propertyRow == null) return [];
    final propertyId = propertyRow['id'] as String;
    final rows = await SupabaseService.client
        .from('appliances')
        .select(_kColumns)
        .eq('property_id', propertyId)
        .isFilter('deleted_at', null)
        .order('category')
        .order('name');
    return rows.map(Appliance.fromJson).toList();
  }

  Future<String> _resolvePropertyId(String userId) async {
    final row = await SupabaseService.client
        .from('properties')
        .select('id')
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) throw Exception('No property found for user');
    return row['id'] as String;
  }
}
