import 'package:supabase_flutter/supabase_flutter.dart';

import '../../documents/repositories/current_property.dart';
import '../models/appliance.dart';
import 'appliances_repository.dart';

/// [AppliancesRepository] on Supabase.
///
/// Deleting and restoring go through the `soft_delete_appliance` and
/// `restore_appliance` functions: a plain UPDATE of `deleted_at` is refused.
class SupabaseAppliancesRepository implements AppliancesRepository {
  const SupabaseAppliancesRepository(this._client);

  final SupabaseClient _client;

  /// Every column the screens read; never `SELECT *`.
  static const String columns =
      'id, property_id, user_id, category, name, status, brand, model, '
      'serial_number, purchase_date, warranty_expiration, purchase_price, '
      'retailer, location, color, lifespan_override, expected_lifespan_min, '
      'expected_lifespan_max, warranty_provider, linked_warranty_doc_id, '
      'notes, estimated_replacement_cost, specifications, '
      'replaced_by_appliance_id, created_at, updated_at';

  @override
  Future<List<Appliance>> list() async {
    final propertyId = await currentPropertyId(_client);
    if (propertyId == null) return const [];
    final rows = await _client
        .from('appliances')
        .select(columns)
        .eq('property_id', propertyId)
        .isFilter('deleted_at', null)
        .order('category')
        .order('name');
    return rows.map(Appliance.fromJson).toList();
  }

  @override
  Future<Appliance?> get(String id) async {
    final propertyId = await currentPropertyId(_client);
    if (propertyId == null) return null;
    final row = await _client
        .from('appliances')
        .select(columns)
        .eq('property_id', propertyId)
        .eq('id', id)
        .isFilter('deleted_at', null)
        .maybeSingle();
    return row == null ? null : Appliance.fromJson(row);
  }

  @override
  Future<String> add(Map<String, dynamic> fields) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');
    final propertyId = await currentPropertyId(_client);
    if (propertyId == null) throw StateError('No property found for user');
    final row = await _client
        .from('appliances')
        .insert({...fields, 'user_id': user.id, 'property_id': propertyId})
        .select('id')
        .single();
    return row['id'] as String;
  }

  @override
  Future<void> update(String id, Map<String, dynamic> fields) => _client
      .from('appliances')
      .update({...fields, 'updated_at': DateTime.now().toUtc().toIso8601String()})
      .eq('id', id);

  @override
  Future<void> softDelete(String id) =>
      _client.rpc('soft_delete_appliance', params: {'p_appliance_id': id});

  @override
  Future<void> restore(String id) =>
      _client.rpc('restore_appliance', params: {'p_appliance_id': id});

  @override
  Future<String?> addressLine() async {
    final propertyId = await currentPropertyId(_client);
    if (propertyId == null) return null;
    final row = await _client
        .from('properties')
        .select('address_line1')
        .eq('id', propertyId)
        .maybeSingle();
    return row?['address_line1'] as String?;
  }
}
