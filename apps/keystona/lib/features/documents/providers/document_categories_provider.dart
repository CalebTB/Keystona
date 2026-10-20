import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/category_icons.dart';
import '../models/category_lists.dart';
import '../models/deleted_category.dart';
import '../models/document_category.dart';
import '../repositories/document_categories_repository.dart';

part 'document_categories_provider.g.dart';

/// The repository behind the category providers. Tests override this with a
/// fake so nothing reaches Supabase.
@riverpod
DocumentCategoriesRepository documentCategoriesRepository(Ref ref) =>
    const SupabaseDocumentCategoriesRepository();

/// Loads all document categories visible to the current user, sorted by
/// [DocumentCategory.sortOrder], and applies edits optimistically.
@riverpod
class DocumentCategoriesNotifier extends _$DocumentCategoriesNotifier {
  DocumentCategoriesRepository get _repo =>
      ref.read(documentCategoriesRepositoryProvider);

  @override
  Future<List<DocumentCategory>> build() =>
      ref.watch(documentCategoriesRepositoryProvider).fetchAll();

  List<DocumentCategory> get _current => state.value ?? const [];

  /// Creates a user-defined category after the existing ones.
  Future<DocumentCategory> create({
    required String name,
    required String icon,
    String color = kCustomCategoryColor,
  }) async {
    final category = await _repo.create(
      name: name,
      icon: icon,
      color: color,
      sortOrder: CategoryLists(_current).nextSortOrder,
    );
    state = AsyncData([..._current, category]);
    return category;
  }

  /// Renames (and re-icons) a user-defined category.
  Future<void> updateCategory(
    String id, {
    required String name,
    required String icon,
    required String color,
  }) async {
    final before = _current;
    state = AsyncData([
      for (final c in before)
        if (c.id == id) c.copyWith(name: name, icon: icon, color: color) else c,
    ]);
    try {
      await _repo.update(id, name: name, icon: icon, color: color);
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
  }

  /// Deletes a user-defined category. Its documents are moved to [moveToId]
  /// (default: the first of Other, Manual, Receipt) and are never deleted.
  /// Returns what moved so the caller can offer Undo.
  Future<DeletedCategory> deleteCategory(String id, {String? moveToId}) async {
    final before = _current;
    final category = before.firstWhere((c) => c.id == id);
    final target = moveToId ?? CategoryLists(before).defaultMoveTarget?.id;
    if (target == null) throw StateError('No category to move documents to');

    state = AsyncData([
      for (final c in before)
        if (c.id != id) c,
    ]);
    try {
      final deleted = await _repo.delete(category, moveToId: target);
      return deleted;
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
  }

  /// Undoes [deleteCategory].
  Future<void> restoreCategory(DeletedCategory deleted) async {
    await _repo.restore(deleted);
    state = AsyncData([..._current, deleted.category]);
  }

  /// Persists a drag of custom category [oldIndex] to [newIndex].
  Future<void> reorderCustom(int oldIndex, int newIndex) async {
    final before = _current;
    final order = CategoryLists(before).reorder(oldIndex, newIndex);
    state = AsyncData([
      for (final c in before)
        if (order.containsKey(c.id)) c.copyWith(sortOrder: order[c.id]!) else c,
    ]);
    try {
      await _repo.reorder(order);
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
  }
}
