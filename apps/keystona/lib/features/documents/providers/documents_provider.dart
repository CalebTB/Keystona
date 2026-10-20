import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../features/subscription/providers/subscription_provider.dart';
import '../../../services/providers/service_providers.dart';
import '../../../services/supabase_service.dart';
import '../models/document.dart';
import '../models/document_quota.dart';
import 'docs_tab_provider.dart';
import 'document_categories_provider.dart';
import 'document_removal.dart';
import 'document_repositories_provider.dart';

part 'documents_provider.g.dart';

/// Live document count per category id for the user's property, unaffected by
/// any filter. Invalidated whenever documents or categories change.
@riverpod
Future<Map<String, int>> documentCategoryCounts(Ref ref) =>
    ref.watch(documentCategoriesRepositoryProvider).documentCounts();

/// Live documents, counted against the free plan's limit. Drives every
/// "N OF 25" label. Invalidated with the other document lists.
@riverpod
Future<int> documentQuotaCount(Ref ref) =>
    ref.watch(documentQuotaRepositoryProvider).used();

/// Loads the Document Vault list for the authenticated user, newest first.
///
/// Search lives in `DocumentSearchRepository`; delete and Undo live in
/// `deleteDocument` / `restoreDocument` (they run on the app container).
@riverpod
class DocumentsNotifier extends _$DocumentsNotifier {
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

    // Property first, then deleted_at. The nested category select avoids an
    // N+1 query.
    final response = await SupabaseService.client
        .from('documents')
        .select(
          'id, name, category_id, document_type_id, created_at, updated_at, '
          'expiration_date, thumbnail_path, file_path, file_size_bytes, '
          'mime_type, page_count, ocr_status, notes, tags, linked_system_id, '
          'linked_appliance_id, '
          'category:document_categories('
          '  id, name, icon, color, is_system, sort_order, created_at, user_id'
          ')',
        )
        .eq('property_id', propertyId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);

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

  /// Triggers a manual re-fetch. Used by pull-to-refresh.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Refreshes the list to include a newly uploaded document.
  ///
  /// For free-tier users, enforces the [kFreeDocumentLimit] before refreshing.
  /// Throws [DocumentLimitException] when the limit is reached.
  Future<Document> add(Map<String, dynamic> data) async {
    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium) {
      final propertyId = data['property_id'] as String?;
      if (propertyId != null) {
        final used = await ref
            .read(documentQuotaRepositoryProvider)
            .usedFor(propertyId);
        if (DocumentQuota.isFull(used)) {
          throw const DocumentLimitException();
        }
      }
    }

    // A provider may not invalidate itself through the shared list helper,
    // so refresh this list with invalidateSelf and the rest through it.
    ref.invalidateSelf();
    invalidateDocumentLists((p) {
      if (p != documentsProvider) ref.invalidate(p);
    });
    await future;
    final docs = state.value ?? [];
    if (docs.isEmpty) throw StateError('No documents after add');
    return docs.first;
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
          'ocr_text, ocr_status, metadata, expiration_date, notes, tags, '
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
    ref.invalidate(docsTabProvider);
  }
}
