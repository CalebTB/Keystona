import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'docs_tab_provider.dart';
import 'document_detail_provider.dart';
import 'document_repositories_provider.dart';
import 'document_search_provider.dart';
import 'documents_provider.dart';
import 'expiring_documents_provider.dart';

/// Refetches every list built from documents: the Docs tab, the vault list,
/// category counts, the expiring list and search. Pass `ref.invalidate` or
/// `container.invalidate`.
void invalidateDocumentLists(void Function(ProviderOrFamily) invalidate) {
  invalidate(documentsProvider);
  invalidate(documentCategoryCountsProvider);
  invalidate(documentQuotaCountProvider);
  invalidate(docsTabProvider);
  invalidate(expiringDocumentsProvider);
  invalidate(documentSearchProvider);
}

/// Soft-deletes a document and refreshes every list.
///
/// Runs on the app [container], not a screen's ref: the detail screen is
/// popped right after, and Undo is tapped when it is already gone. The detail
/// provider is left alone, so the open screen does not refetch a deleted row.
Future<void> deleteDocument(ProviderContainer container, String id) async {
  await container.read(documentMutationsRepositoryProvider).softDelete(id);
  invalidateDocumentLists(container.invalidate);
}

/// Undoes [deleteDocument] and refreshes every list and the detail screen.
Future<void> restoreDocument(ProviderContainer container, String id) async {
  await container.read(documentMutationsRepositoryProvider).restore(id);
  invalidateDocumentLists(container.invalidate);
  container.invalidate(documentDetailProvider(id));
}
