import 'package:keystona/features/home_profile/models/item_ref.dart';
import 'package:keystona/features/home_profile/models/item_service_entry.dart';
import 'package:keystona/features/home_profile/repositories/item_service_log_repository.dart';

/// In-memory service log: nothing reaches Supabase.
class FakeItemServiceLogRepository implements ItemServiceLogRepository {
  FakeItemServiceLogRepository([List<ItemServiceEntry> entries = const []])
    : entries = [...entries];

  final List<ItemServiceEntry> entries;
  final List<String> calls = [];

  /// Makes every write throw.
  Object? failWrites;
  int _nextId = 1;

  @override
  Future<List<ItemServiceEntry>> list(ItemRef item) async {
    calls.add('list');
    return [
      for (final e in entries)
        if (e.item == item) e,
    ]..sort(ItemServiceEntry.newestFirst);
  }

  @override
  Future<ItemServiceEntry> add(ItemRef item, ItemServiceDraft draft) async {
    if (failWrites != null) throw failWrites!;
    calls.add('add');
    final entry = ItemServiceEntry(
      id: 'new${_nextId++}',
      item: item,
      kind: draft.kind,
      serviceDate: draft.serviceDate,
      title: draft.title,
      provider: draft.provider,
      cost: draft.cost,
      note: draft.note,
      underWarranty: draft.underWarranty,
      documentId: draft.documentId,
    );
    entries.add(entry);
    return entry;
  }

  @override
  Future<void> update(String entryId, ItemServiceDraft draft) async {
    if (failWrites != null) throw failWrites!;
    calls.add('update:$entryId');
    final i = entries.indexWhere((e) => e.id == entryId);
    entries[i] = entries[i].withDraft(draft);
  }

  @override
  Future<void> delete(String entryId) async {
    if (failWrites != null) throw failWrites!;
    calls.add('delete:$entryId');
    entries.removeWhere((e) => e.id == entryId);
  }

  @override
  Future<void> reinsert(ItemServiceEntry entry) async {
    if (failWrites != null) throw failWrites!;
    calls.add('reinsert:${entry.id}');
    entries.add(entry);
  }
}
