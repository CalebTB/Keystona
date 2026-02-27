import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../models/document.dart';

part 'documents_provider.g.dart';

/// Sort options available from the Documents screen overflow menu.
enum DocumentSortOrder {
  /// Newest first (default).
  dateAddedDesc,

  /// Alphabetical A to Z.
  nameAsc,

  /// By category sort order, then name.
  categoryAsc,
}

/// Loads and manages the Document Vault list for the authenticated user.
///
/// Filtering by category and search query is controlled via [setCategory] and
/// [setSearchQuery]. Sort order is changed via [setSortOrder].
///
/// Extension points for downstream issues:
/// - [setSearchQuery] — implemented by issue #23 (full-text + OCR search)
/// - [add]           — implemented by issue #21 (upload flow)
/// - [getById]       — implemented by issue #22 (detail screen)
/// - [updateDocument] — implemented by issue #22 (edit metadata)
/// - [softDelete]    — implemented by issue #22 (delete document)
@riverpod
class DocumentsNotifier extends _$DocumentsNotifier {
  String? _categoryId;
  DocumentSortOrder _sortOrder = DocumentSortOrder.dateAddedDesc;

  @override
  Future<List<Document>> build() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return [];

    // Fetch the user's primary property. Returns null if onboarding incomplete.
    final profileRow = await SupabaseService.client
        .from('properties')
        .select('id')
        .eq('user_id', user.id)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (profileRow == null) return [];
    final propertyId = profileRow['id'] as String;

    // Build the base filter chain. Always filter by property first, then
    // deleted_at. The nested category select avoids an N+1 query.
    var filterQuery = SupabaseService.client
        .from('documents')
        .select(
          'id, name, category_id, document_type_id, created_at, updated_at, '
          'expiration_date, thumbnail_path, file_path, file_size_bytes, '
          'mime_type, page_count, ocr_status, notes, linked_system_id, '
          'linked_appliance_id, '
          'category:document_categories('
          '  id, name, icon, color, is_system, sort_order, created_at, user_id'
          ')',
        )
        .eq('property_id', propertyId)
        .isFilter('deleted_at', null);

    if (_categoryId != null) {
      filterQuery = filterQuery.eq('category_id', _categoryId!);
    }

    // Apply sort. The filter query must be finalised before ordering because
    // PostgrestFilterBuilder and PostgrestTransformBuilder are different types.
    final List<Map<String, dynamic>> response;
    switch (_sortOrder) {
      case DocumentSortOrder.dateAddedDesc:
        response = await filterQuery.order('created_at', ascending: false);
      case DocumentSortOrder.nameAsc:
        response = await filterQuery.order('name', ascending: true);
      case DocumentSortOrder.categoryAsc:
        response = await filterQuery
            .order('category_id', ascending: true)
            .order('name', ascending: true);
    }

    return response.map((json) {
      return Document.fromJson({
        ...json,
        'user_id': user.id,
        'property_id': propertyId,
        'metadata': json['metadata'] ?? <String, dynamic>{},
      });
    }).toList();
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Filters the document list by [categoryId].
  ///
  /// Pass null to clear the filter and show all categories.
  void setCategory(String? categoryId) {
    _categoryId = categoryId;
    ref.invalidateSelf();
  }

  /// Changes the sort order of the document list.
  void setSortOrder(DocumentSortOrder order) {
    _sortOrder = order;
    ref.invalidateSelf();
  }

  /// Triggers a manual re-fetch. Used by pull-to-refresh.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  // ── Stubs for downstream issues ─────────────────────────────────────────────

  /// Full-text and OCR search across documents. Implemented by issue #23.
  void setSearchQuery(String? query) {
    throw UnimplementedError('setSearchQuery() implemented by issue #23');
  }

  /// Uploads and creates a new document. Implemented by issue #21.
  Future<Document> add(Map<String, dynamic> data) {
    throw UnimplementedError('add() implemented by issue #21');
  }

  /// Fetches a single document by ID. Implemented by issue #22.
  Future<Document> getById(String id) {
    throw UnimplementedError('getById() implemented by issue #22');
  }

  /// Updates document metadata fields. Implemented by issue #22.
  ///
  /// Named [updateDocument] to avoid collision with [AsyncNotifier.update].
  Future<void> updateDocument(String id, Map<String, dynamic> changes) {
    throw UnimplementedError('updateDocument() implemented by issue #22');
  }

  /// Soft-deletes a document (sets deleted_at). Implemented by issue #22.
  Future<void> softDelete(String id) {
    throw UnimplementedError('softDelete() implemented by issue #22');
  }
}
