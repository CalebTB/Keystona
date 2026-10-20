import '../models/item_ref.dart';
import '../models/item_service_entry.dart';

/// Pure builders for `item_service_log` writes.
abstract final class ItemServiceRows {
  /// `YYYY-MM-DD` for a DATE column (a full timestamp is rejected).
  static String dateColumn(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// The editable columns of [draft].
  static Map<String, dynamic> fields(ItemServiceDraft draft) => {
    'kind': draft.kind.value,
    'service_date': dateColumn(draft.serviceDate),
    'title': draft.title,
    'provider': draft.provider,
    'cost': draft.cost,
    'note': draft.note,
    'under_warranty': draft.underWarranty,
    'document_id': draft.documentId,
  };

  /// A new row. Exactly one of `system_id` / `appliance_id` is set, and
  /// `user_id` and `property_id` are always present. Pass [id] to re-insert a
  /// deleted row under its old id (Undo).
  static Map<String, dynamic> insert({
    required ItemRef item,
    required String propertyId,
    required String userId,
    required ItemServiceDraft draft,
    String? id,
  }) => {
    'id': ?id,
    'property_id': propertyId,
    'user_id': userId,
    'system_id': item.isSystem ? item.id : null,
    'appliance_id': item.isAppliance ? item.id : null,
    ...fields(draft),
  };

  /// The insert that puts [entry] back (Undo of a delete).
  static Map<String, dynamic> reinsert({
    required ItemServiceEntry entry,
    required String propertyId,
    required String userId,
  }) => insert(
    item: entry.item,
    propertyId: propertyId,
    userId: userId,
    id: entry.id,
    draft: ItemServiceDraft(
      kind: entry.kind,
      serviceDate: entry.serviceDate,
      title: entry.title,
      provider: entry.provider,
      cost: entry.cost,
      note: entry.note,
      underWarranty: entry.underWarranty,
      documentId: entry.documentId,
    ),
  );

  /// The update for an edited entry: the editable columns only.
  static Map<String, dynamic> update(ItemServiceDraft draft) => fields(draft);
}
