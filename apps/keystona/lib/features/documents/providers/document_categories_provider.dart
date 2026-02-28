import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../models/document_category.dart';

part 'document_categories_provider.g.dart';

/// Loads all document categories visible to the current user.
///
/// Returns both system categories (is_system = true) and any custom categories
/// created by this user, sorted by [DocumentCategory.sortOrder].
///
/// Extension points for issue #25:
/// - [create] — add a user-defined category
/// - [updateCategory] — rename or recolor an existing category
/// - [deleteCategory] — remove a user-defined category
@riverpod
class DocumentCategoriesNotifier extends _$DocumentCategoriesNotifier {
  @override
  Future<List<DocumentCategory>> build() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return [];

    final response = await SupabaseService.client
        .from('document_categories')
        .select('id, name, icon, color, is_system, sort_order, created_at, user_id')
        .or('is_system.eq.true,user_id.eq.${user.id}')
        .order('sort_order');

    return response.map((json) => DocumentCategory.fromJson(json)).toList();
  }

  // ── Mutations (issue #25) ───────────────────────────────────────────────────

  /// Creates a user-defined category with the given [name], [icon], and [color].
  ///
  /// [icon] must be one of the keys in [CategoryIcons.all].
  /// [color] is a hex string, e.g. '#0097A7'.
  Future<DocumentCategory> create({
    required String name,
    required String icon,
    required String color,
  }) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) throw StateError('User not authenticated');

    // Sort the new category after any existing custom categories.
    final existing = state.value ?? [];
    final maxOrder = existing.fold<int>(
      0,
      (max, c) => c.sortOrder > max ? c.sortOrder : max,
    );

    final row = await SupabaseService.client
        .from('document_categories')
        .insert({
          'user_id': user.id,
          'name': name,
          'icon': icon,
          'color': color,
          'is_system': false,
          'sort_order': maxOrder + 1,
        })
        .select('id, name, icon, color, is_system, sort_order, created_at, user_id')
        .single();

    final category = DocumentCategory.fromJson(row);
    ref.invalidateSelf();
    return category;
  }

  /// Updates the [name], [icon], and [color] of an existing user-defined category.
  Future<void> updateCategory(
    String id, {
    required String name,
    required String icon,
    required String color,
  }) async {
    await SupabaseService.client
        .from('document_categories')
        .update({'name': name, 'icon': icon, 'color': color})
        .eq('id', id);

    ref.invalidateSelf();
  }

  /// Deletes a user-defined category.
  ///
  /// All documents currently assigned to [id] are moved to the system
  /// "Uncategorized" category (lowest sort_order system category) before
  /// the category row is deleted. This prevents orphaned documents.
  Future<void> deleteCategory(String id) async {
    // Find the fallback category. The spec calls this "Uncategorized";
    // we use the lowest sort_order system category as a safe default
    // when a dedicated "Uncategorized" row is not yet seeded.
    final fallbackRow = await SupabaseService.client
        .from('document_categories')
        .select('id')
        .eq('is_system', true)
        .order('sort_order')
        .limit(1)
        .single();
    final fallbackId = fallbackRow['id'] as String;

    // Move all non-deleted documents in this category to the fallback.
    await SupabaseService.client
        .from('documents')
        .update({'category_id': fallbackId})
        .eq('category_id', id)
        .isFilter('deleted_at', null);

    // Delete the category row (RLS prevents deleting system categories).
    await SupabaseService.client
        .from('document_categories')
        .delete()
        .eq('id', id);

    ref.invalidateSelf();
  }
}
