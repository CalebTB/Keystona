import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/item_ref.dart';
import '../models/item_summary.dart';

/// Looks up a system or appliance by id for the shared item screens.
abstract interface class ItemSummaryRepository {
  /// The item, or null when it does not exist (or was deleted).
  Future<ItemSummary?> get(ItemRef item);
}

/// [ItemSummaryRepository] on Supabase.
class SupabaseItemSummaryRepository implements ItemSummaryRepository {
  const SupabaseItemSummaryRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<ItemSummary?> get(ItemRef item) async {
    final row = await _client
        .from(item.isSystem ? 'systems' : 'appliances')
        .select('id, name, brand, model')
        .eq('id', item.id)
        .isFilter('deleted_at', null)
        .maybeSingle();
    if (row == null) return null;
    return ItemSummary(
      item: item,
      name: row['name'] as String,
      brand: row['brand'] as String?,
      model: row['model'] as String?,
    );
  }
}
