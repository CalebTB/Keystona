import '../../../services/supabase_service.dart';
import '../models/category_icons.dart';
import '../models/deleted_category.dart';
import '../models/document_category.dart';

/// Data access for document categories.
abstract interface class DocumentCategoriesRepository {
  /// System categories plus the signed-in user's own, in sort order.
  Future<List<DocumentCategory>> fetchAll();

  /// Live document count per category id for the user's property.
  Future<Map<String, int>> documentCounts();

  Future<DocumentCategory> create({
    required String name,
    required String icon,
    required String color,
    required int sortOrder,
  });

  Future<void> update(
    String id, {
    required String name,
    required String icon,
    required String color,
  });

  /// Moves every live document of [category] into [moveToId], then deletes
  /// [category]. Returns what moved, so the delete can be undone.
  Future<DeletedCategory> delete(
    DocumentCategory category, {
    required String moveToId,
  });

  /// Puts a deleted category back and moves its documents back into it.
  Future<void> restore(DeletedCategory deleted);

  /// Writes `sort_order` for each `id -> order` entry.
  Future<void> reorder(Map<String, int> sortOrders);
}

/// Supabase-backed [DocumentCategoriesRepository].
class SupabaseDocumentCategoriesRepository
    implements DocumentCategoriesRepository {
  const SupabaseDocumentCategoriesRepository();

  static const String _columns =
      'id, name, icon, color, is_system, sort_order, created_at, user_id';

  String get _userId {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) throw StateError('User not authenticated');
    return user.id;
  }

  @override
  Future<List<DocumentCategory>> fetchAll() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return [];
    final rows = await SupabaseService.client
        .from('document_categories')
        .select(_columns)
        .or('is_system.eq.true,user_id.eq.${user.id}')
        .order('sort_order');
    return rows.map(DocumentCategory.fromJson).toList();
  }

  @override
  Future<Map<String, int>> documentCounts() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return {};
    final property = await SupabaseService.client
        .from('properties')
        .select('id')
        .eq('user_id', user.id)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (property == null) return {};

    final rows = await SupabaseService.client
        .from('documents')
        .select('category_id')
        .eq('property_id', property['id'] as String)
        .isFilter('deleted_at', null);
    final counts = <String, int>{};
    for (final row in rows) {
      final id = row['category_id'] as String?;
      if (id != null) counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Future<DocumentCategory> create({
    required String name,
    required String icon,
    required String color,
    required int sortOrder,
  }) async {
    final row = await SupabaseService.client
        .from('document_categories')
        .insert({
          'user_id': _userId,
          'name': name,
          'icon': icon,
          'color': color,
          'is_system': false,
          'sort_order': sortOrder,
        })
        .select(_columns)
        .single();
    return DocumentCategory.fromJson(row);
  }

  @override
  Future<void> update(
    String id, {
    required String name,
    required String icon,
    required String color,
  }) async {
    await SupabaseService.client
        .from('document_categories')
        .update({'name': name, 'icon': icon, 'color': color})
        .eq('id', id);
  }

  @override
  Future<DeletedCategory> delete(
    DocumentCategory category, {
    required String moveToId,
  }) async {
    final docs = await SupabaseService.client
        .from('documents')
        .select('id')
        .eq('category_id', category.id)
        .isFilter('deleted_at', null);
    final ids = [for (final row in docs) row['id'] as String];

    if (ids.isNotEmpty) {
      await SupabaseService.client
          .from('documents')
          .update({'category_id': moveToId})
          .inFilter('id', ids);
    }
    // RLS prevents deleting system categories.
    await SupabaseService.client
        .from('document_categories')
        .delete()
        .eq('id', category.id);

    return DeletedCategory(
      category: category,
      movedDocumentIds: ids,
      movedToCategoryId: moveToId,
    );
  }

  @override
  Future<void> restore(DeletedCategory deleted) async {
    final c = deleted.category;
    await SupabaseService.client.from('document_categories').insert({
      'id': c.id,
      'user_id': _userId,
      'name': c.name,
      'icon': c.icon.isEmpty ? CategoryIcons.defaultKey : c.icon,
      'color': c.color,
      'is_system': false,
      'sort_order': c.sortOrder,
    });
    if (deleted.movedDocumentIds.isNotEmpty) {
      await SupabaseService.client
          .from('documents')
          .update({'category_id': c.id})
          .inFilter('id', deleted.movedDocumentIds);
    }
  }

  @override
  Future<void> reorder(Map<String, int> sortOrders) async {
    await Future.wait([
      for (final entry in sortOrders.entries)
        SupabaseService.client
            .from('document_categories')
            .update({'sort_order': entry.value})
            .eq('id', entry.key),
    ]);
  }
}
