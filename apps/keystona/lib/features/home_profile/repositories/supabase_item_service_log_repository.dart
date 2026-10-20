import '../../../services/supabase_service.dart';
import '../models/item_ref.dart';
import '../models/item_service_entry.dart';
import 'item_service_log_repository.dart';
import 'item_service_rows.dart';

/// [ItemServiceLogRepository] backed by Supabase. RLS is the auth layer.
class SupabaseItemServiceLogRepository implements ItemServiceLogRepository {
  const SupabaseItemServiceLogRepository();

  static const String _table = 'item_service_log';

  Future<({String userId, String propertyId})> _owner() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');
    final row = await SupabaseService.client
        .from('properties')
        .select('id')
        .eq('user_id', user.id)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    final propertyId = row?['id'] as String?;
    if (propertyId == null) throw StateError('No property found');
    return (userId: user.id, propertyId: propertyId);
  }

  @override
  Future<List<ItemServiceEntry>> list(ItemRef item) async {
    final rows = await SupabaseService.client
        .from(_table)
        .select(ItemServiceColumns.all)
        .eq(item.isSystem ? 'system_id' : 'appliance_id', item.id)
        .order('service_date', ascending: false)
        .order('created_at', ascending: false);
    return rows.map(ItemServiceEntry.fromRow).toList();
  }

  @override
  Future<ItemServiceEntry> add(ItemRef item, ItemServiceDraft draft) async {
    final owner = await _owner();
    final row = await SupabaseService.client
        .from(_table)
        .insert(
          ItemServiceRows.insert(
            item: item,
            propertyId: owner.propertyId,
            userId: owner.userId,
            draft: draft,
          ),
        )
        .select(ItemServiceColumns.all)
        .single();
    return ItemServiceEntry.fromRow(row);
  }

  @override
  Future<void> update(String entryId, ItemServiceDraft draft) async {
    await SupabaseService.client
        .from(_table)
        .update(ItemServiceRows.update(draft))
        .eq('id', entryId);
  }

  @override
  Future<void> delete(String entryId) async {
    await SupabaseService.client.from(_table).delete().eq('id', entryId);
  }

  @override
  Future<void> reinsert(ItemServiceEntry entry) async {
    final owner = await _owner();
    await SupabaseService.client
        .from(_table)
        .insert(
          ItemServiceRows.reinsert(
            entry: entry,
            propertyId: owner.propertyId,
            userId: owner.userId,
          ),
        );
  }
}
