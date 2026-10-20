import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/item_ref.dart';
import '../models/item_service_entry.dart';
import '../repositories/item_service_log_repository.dart';
import '../repositories/supabase_item_service_log_repository.dart';

part 'item_service_log_provider.g.dart';

/// The data source behind the history timeline. Tests override it.
final itemServiceLogRepositoryProvider = Provider<ItemServiceLogRepository>(
  (ref) => const SupabaseItemServiceLogRepository(),
);

/// An item's service history, newest first, plus the changes the detail
/// screens make to it.
///
/// Changes are optimistic where the id is known (edit, delete, undo); an add
/// waits for the row so it has its database id. The state never goes to
/// loading around a write; a failed write puts the list back and rethrows.
@riverpod
class ItemServiceLog extends _$ItemServiceLog {
  @override
  Future<List<ItemServiceEntry>> build(ItemRef item) =>
      ref.read(itemServiceLogRepositoryProvider).list(item);

  List<ItemServiceEntry> get _entries => state.value ?? const [];

  void _set(List<ItemServiceEntry> entries) =>
      state = AsyncData([...entries]..sort(ItemServiceEntry.newestFirst));

  /// Logs a new entry and returns it.
  Future<ItemServiceEntry> add(ItemServiceDraft draft) async {
    final created = await ref
        .read(itemServiceLogRepositoryProvider)
        .add(item, draft);
    _set([..._entries, created]);
    return created;
  }

  /// Rewrites [entry] with [draft].
  Future<void> edit(ItemServiceEntry entry, ItemServiceDraft draft) async {
    final before = _entries;
    _set([for (final e in before) e.id == entry.id ? e.withDraft(draft) : e]);
    try {
      await ref.read(itemServiceLogRepositoryProvider).update(entry.id, draft);
    } catch (_) {
      _set(before);
      rethrow;
    }
  }

  /// Deletes [entry]. Pass the same entry to [restore] to undo.
  Future<void> remove(ItemServiceEntry entry) async {
    final before = _entries;
    _set([
      for (final e in before)
        if (e.id != entry.id) e,
    ]);
    try {
      await ref.read(itemServiceLogRepositoryProvider).delete(entry.id);
    } catch (_) {
      _set(before);
      rethrow;
    }
  }

  /// Undo of [remove]: puts [entry] back under its old id.
  Future<void> restore(ItemServiceEntry entry) async {
    final before = _entries;
    _set([...before, entry]);
    try {
      await ref.read(itemServiceLogRepositoryProvider).reinsert(entry);
    } catch (_) {
      _set(before);
      rethrow;
    }
  }
}
