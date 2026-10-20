import 'package:supabase_flutter/supabase_flutter.dart';

import '../../documents/repositories/current_property.dart';
import '../models/item_completion.dart';
import '../models/item_ref.dart';

/// Reads the finished tasks of a system or appliance.
abstract interface class ItemCompletionsRepository {
  /// Completions of the item's tasks, newest first.
  Future<List<ItemCompletion>> list(ItemRef item);
}

/// [ItemCompletionsRepository] on Supabase: `task_completions` reach an item
/// only through their task.
class SupabaseItemCompletionsRepository implements ItemCompletionsRepository {
  const SupabaseItemCompletionsRepository(this._client);

  final SupabaseClient _client;

  static const String columns =
      'id, completed_date, completed_by, contractor_name, contractor_company, '
      'service_cost, materials_cost, '
      'task:maintenance_tasks!inner(name, linked_system_id, linked_appliance_id)';

  /// The most completions read for one item.
  static const int limit = 500;

  @override
  Future<List<ItemCompletion>> list(ItemRef item) async {
    final propertyId = await currentPropertyId(_client);
    if (propertyId == null) return const [];
    final linkColumn = item.isSystem
        ? 'task.linked_system_id'
        : 'task.linked_appliance_id';
    final rows = await _client
        .from('task_completions')
        .select(columns)
        .eq('property_id', propertyId)
        .eq(linkColumn, item.id)
        .isFilter('task.deleted_at', null)
        .order('completed_date', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map(ItemCompletion.fromRow).toList();
  }
}
