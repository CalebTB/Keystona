import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/providers/service_providers.dart';
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
/// - [add]           — implemented by issue #21 (upload flow)
/// - [getById]       — implemented by issue #22 (detail screen)
/// - [updateDocument] — implemented by issue #22 (edit metadata)
/// - [softDelete]    — implemented by issue #22 (delete document)
@riverpod
class DocumentsNotifier extends _$DocumentsNotifier {
  String? _categoryId;
  DocumentSortOrder _sortOrder = DocumentSortOrder.dateAddedDesc;
  String? _searchQuery;

  /// OCR search snippets keyed by document ID. Only populated for premium
  /// users during an active search. Cleared when search is reset.
  final Map<String, String> _snippets = {};

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

    // Delegate to search when a query is active.
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      return _performSearch(propertyId, user.id, _searchQuery!);
    }

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

  // ── Search ──────────────────────────────────────────────────────────────────

  /// True when a non-empty search query is active.
  bool get isSearchActive =>
      _searchQuery != null && _searchQuery!.isNotEmpty;

  /// Returns the OCR snippet for [docId] if one exists (premium search only).
  String? snippetFor(String docId) => _snippets[docId];

  /// Sets the active search query and re-fetches.
  ///
  /// Pass null or empty string to clear the search and restore the normal list.
  void setSearchQuery(String? query) {
    final trimmed = query?.trim();
    _searchQuery = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    _snippets.clear();
    ref.invalidateSelf();
  }

  /// Refreshes the list to include a newly uploaded document.
  Future<Document> add(Map<String, dynamic> data) async {
    ref.invalidateSelf();
    await future;
    final docs = state.value ?? [];
    if (docs.isEmpty) throw StateError('No documents after add');
    return docs.first;
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  Future<List<Document>> _performSearch(
    String propertyId,
    String userId,
    String query,
  ) async {
    _snippets.clear();
    final isPremium = ref.read(isPremiumProvider);

    if (isPremium) {
      // Premium: ranked full-text OCR search via RPC. Returns snippet per row.
      final rows = await SupabaseService.client.rpc<List<dynamic>>(
        'search_documents',
        params: {
          'p_property_id': propertyId,
          'p_query': query,
          'p_limit': 20,
        },
      );

      final docs = <Document>[];
      for (final row in rows.cast<Map<String, dynamic>>()) {
        final snippet = row['snippet'] as String?;
        final docId = row['id'] as String;
        if (snippet != null && snippet.isNotEmpty) {
          _snippets[docId] = snippet;
        }
        docs.add(Document.fromJson({
          ...row,
          'user_id': userId,
          'property_id': propertyId,
          'metadata': row['metadata'] ?? <String, dynamic>{},
          'deleted_at': null,
        }));
      }
      return docs;
    } else {
      // Free tier: trigram name search using ILIKE — hits idx_documents_search.
      final response = await SupabaseService.client
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
          .isFilter('deleted_at', null)
          .ilike('name', '%$query%')
          .order('created_at', ascending: false)
          .limit(25);

      return (response as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((json) => Document.fromJson({
                ...json,
                'user_id': userId,
                'property_id': propertyId,
                'metadata': json['metadata'] ?? <String, dynamic>{},
              }))
          .toList();
    }
  }

  // ── Implemented by issue #22 ────────────────────────────────────────────────

  /// Fetches a single document by ID with full joins (category + type).
  ///
  /// Throws a [StateError] when the document does not exist or has been
  /// soft-deleted.
  Future<Document> getById(String id) async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');

    final row = await SupabaseService.client
        .from('documents')
        .select(
          'id, name, category_id, document_type_id, file_path, '
          'thumbnail_path, file_size_bytes, mime_type, page_count, '
          'ocr_text, ocr_status, metadata, expiration_date, notes, '
          'linked_system_id, linked_appliance_id, created_at, updated_at, '
          'deleted_at, '
          'category:document_categories('
          '  id, name, icon, color, is_system, sort_order, created_at, user_id'
          '), '
          'type:document_types(id, category_id, name, description, sort_order)',
        )
        .eq('id', id)
        .isFilter('deleted_at', null)
        .single();

    // Inject user_id and property_id from the auth context. The property_id
    // is not fetched here to avoid a second query; the join on documents
    // (which are always scoped to a property by RLS) guarantees ownership.
    return Document.fromJson({
      ...row,
      'user_id': user.id,
      'property_id': row['property_id'] ?? '',
      'metadata': row['metadata'] ?? <String, dynamic>{},
    });
  }

  /// Updates the mutable metadata fields of a document.
  ///
  /// Only pass the fields that have changed. The list is automatically
  /// invalidated so callers see the updated document on the next frame.
  ///
  /// Named [updateDocument] to avoid collision with [AsyncNotifier.update].
  Future<void> updateDocument(String id, Map<String, dynamic> changes) async {
    await SupabaseService.client
        .from('documents')
        .update(changes)
        .eq('id', id);

    ref.invalidateSelf();
  }

  /// Soft-deletes a document by setting [deleted_at] to the current time.
  ///
  /// The document is immediately excluded from all list queries. The list
  /// provider is invalidated so the change is reflected without a manual
  /// refresh.
  Future<void> softDelete(String id) async {
    await SupabaseService.client
        .from('documents')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);

    ref.invalidateSelf();
  }

  /// Restores a soft-deleted document by clearing [deleted_at].
  ///
  /// Used by the undo-delete flow on the detail screen.
  Future<void> restore(String id) async {
    await SupabaseService.client
        .from('documents')
        .update({'deleted_at': null})
        .eq('id', id);

    ref.invalidateSelf();
  }
}
