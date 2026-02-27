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

  // ── Stubs for issue #25 ─────────────────────────────────────────────────────

  /// Creates a user-defined category. Implemented by issue #25.
  // ignore: unused_element
  Future<DocumentCategory> create(Map<String, dynamic> data) {
    throw UnimplementedError('create() implemented by issue #25');
  }

  /// Updates an existing category. Implemented by issue #25.
  // ignore: unused_element
  Future<void> updateCategory(String id, Map<String, dynamic> changes) {
    throw UnimplementedError('updateCategory() implemented by issue #25');
  }

  /// Soft-deletes a user-defined category. Implemented by issue #25.
  // ignore: unused_element
  Future<void> deleteCategory(String id) {
    throw UnimplementedError('deleteCategory() implemented by issue #25');
  }
}
