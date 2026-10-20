import 'package:supabase_flutter/supabase_flutter.dart';

import '../../documents/repositories/current_property.dart';
import '../models/item_document.dart';
import '../models/item_ref.dart';

/// Reads the documents in Docs that belong to a system or appliance.
abstract interface class ItemDocumentsRepository {
  /// Documents linked to the item, plus [warrantyDocId] when the item points
  /// at one. Newest first.
  Future<List<ItemDocument>> list(ItemRef item, {String? warrantyDocId});
}

/// [ItemDocumentsRepository] on Supabase. Read only.
class SupabaseItemDocumentsRepository implements ItemDocumentsRepository {
  const SupabaseItemDocumentsRepository(this._client);

  final SupabaseClient _client;

  static const String columns =
      'id, name, mime_type, page_count, expiration_date, created_at, '
      'type:document_types(name)';

  @override
  Future<List<ItemDocument>> list(
    ItemRef item, {
    String? warrantyDocId,
  }) async {
    final propertyId = await currentPropertyId(_client);
    if (propertyId == null) return const [];
    final linkColumn = item.isSystem ? 'linked_system_id' : 'linked_appliance_id';
    final match = warrantyDocId == null
        ? '$linkColumn.eq.${item.id}'
        : '$linkColumn.eq.${item.id},id.eq.$warrantyDocId';
    final rows = await _client
        .from('documents')
        .select(columns)
        .eq('property_id', propertyId)
        .isFilter('deleted_at', null)
        .or(match)
        .order('created_at', ascending: false);
    return rows.map(ItemDocument.fromRow).toList();
  }
}
