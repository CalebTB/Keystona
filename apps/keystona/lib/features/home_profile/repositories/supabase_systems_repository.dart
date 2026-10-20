import '../../../services/supabase_service.dart';
import '../models/property_brief.dart';
import '../models/system.dart';
import 'system_columns.dart';
import 'systems_repository.dart';

/// [SystemsRepository] backed by Supabase. RLS is the auth layer; deletes and
/// restores go through the SECURITY DEFINER functions because a plain UPDATE
/// of `deleted_at` fails with 42501.
class SupabaseSystemsRepository implements SystemsRepository {
  const SupabaseSystemsRepository();

  static const String _table = 'systems';

  @override
  Future<PropertyBrief?> property() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');
    final row = await SupabaseService.client
        .from('properties')
        .select('id, address_line1, year_built')
        .eq('user_id', user.id)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return PropertyBrief(
      id: row['id'] as String,
      addressLine1: row['address_line1'] as String?,
      yearBuilt: (row['year_built'] as num?)?.toInt(),
    );
  }

  @override
  Future<List<HomeSystem>> list() async {
    final property = await this.property();
    if (property == null) return const [];
    final rows = await SupabaseService.client
        .from(_table)
        .select(SystemColumns.all)
        .eq('property_id', property.id)
        .isFilter('deleted_at', null)
        .order('category')
        .order('name');
    return rows
        .map((r) => HomeSystem.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  @override
  Future<HomeSystem> fetch(String id) async {
    final row = await SupabaseService.client
        .from(_table)
        .select(SystemColumns.all)
        .eq('id', id)
        .isFilter('deleted_at', null)
        .single();
    return HomeSystem.fromJson(Map<String, dynamic>.from(row));
  }

  @override
  Future<String> create(Map<String, dynamic> fields) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');
    final property = await this.property();
    if (property == null) throw StateError('No property found');
    final row = await SupabaseService.client
        .from(_table)
        .insert({'property_id': property.id, 'user_id': user.id, ...fields})
        .select('id')
        .single();
    return row['id'] as String;
  }

  @override
  Future<void> update(String id, Map<String, dynamic> fields) async {
    await SupabaseService.client.from(_table).update(fields).eq('id', id);
  }

  @override
  Future<void> softDelete(String id) async {
    await SupabaseService.client.rpc(
      'soft_delete_system',
      params: {'p_system_id': id},
    );
  }

  @override
  Future<void> restore(String id) async {
    await SupabaseService.client.rpc(
      'restore_system',
      params: {'p_system_id': id},
    );
  }
}
