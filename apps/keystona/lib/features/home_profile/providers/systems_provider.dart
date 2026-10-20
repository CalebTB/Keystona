import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/property_brief.dart';
import '../models/system.dart';
import 'home_profile_provider.dart';
import 'system_repositories_provider.dart';

part 'systems_provider.g.dart';

/// The property facts the Systems screens show (street, year built).
@riverpod
Future<PropertyBrief?> propertyBrief(Ref ref) =>
    ref.read(systemsRepositoryProvider).property();

/// The list of home systems for the user's property, and the changes the
/// screens make to it.
///
/// Kept alive so other features (the document link picker) read the same
/// cached list. A change that writes (add, edit) refetches the list; delete
/// and its Undo are optimistic. The state never goes to loading around a
/// write. Overview counts ([homeProfileProvider]) are refreshed after every
/// change.
@riverpod
class SystemsNotifier extends _$SystemsNotifier {
  @override
  Future<List<HomeSystem>> build() {
    ref.keepAlive();
    return ref.read(systemsRepositoryProvider).list();
  }

  List<HomeSystem> get _systems => state.value ?? const [];

  /// Refetches the list. Keeps showing the current list while it loads.
  Future<void> refresh() async {
    state = await AsyncValue.guard(ref.read(systemsRepositoryProvider).list);
  }

  /// Inserts a system and returns its id.
  Future<String> addSystem(Map<String, dynamic> fields) async {
    final id = await ref.read(systemsRepositoryProvider).create(fields);
    await _refreshAfterWrite();
    return id;
  }

  /// Updates columns of one system.
  Future<void> updateSystem(String id, Map<String, dynamic> fields) async {
    await ref.read(systemsRepositoryProvider).update(id, fields);
    await _refreshAfterWrite();
  }

  /// Soft-deletes [id] (`soft_delete_system`). The row leaves the list at
  /// once; a failed write puts it back and rethrows. Undo with [restoreSystem].
  Future<void> deleteSystem(String id) async {
    final before = _systems;
    state = AsyncData([
      for (final s in before)
        if (s.id != id) s,
    ]);
    try {
      await ref.read(systemsRepositoryProvider).softDelete(id);
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
    ref.invalidate(homeProfileProvider);
  }

  /// Undo of [deleteSystem] (`restore_system`).
  Future<void> restoreSystem(String id) async {
    await ref.read(systemsRepositoryProvider).restore(id);
    await _refreshAfterWrite();
  }

  Future<void> _refreshAfterWrite() async {
    ref.invalidate(homeProfileProvider);
    await refresh();
  }
}
