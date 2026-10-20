import '../models/item_ref.dart';
import '../models/item_service_entry.dart';

/// Reads and writes an item's service history (`item_service_log`).
///
/// Notifiers depend on this interface through
/// `itemServiceLogRepositoryProvider`; tests override it with a fake.
abstract interface class ItemServiceLogRepository {
  /// The item's entries, newest first.
  Future<List<ItemServiceEntry>> list(ItemRef item);

  /// Logs a new entry and returns it with its id.
  Future<ItemServiceEntry> add(ItemRef item, ItemServiceDraft draft);

  /// Rewrites the editable fields of [entryId].
  Future<void> update(String entryId, ItemServiceDraft draft);

  /// Hard-deletes [entryId].
  Future<void> delete(String entryId);

  /// Puts a deleted [entry] back under its old id (Undo).
  Future<void> reinsert(ItemServiceEntry entry);
}
