import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../models/document.dart';
import 'documents_provider.dart';

part 'document_detail_provider.g.dart';

/// Manages the state for the Document Detail screen.
///
/// Keyed by document [id] and auto-disposed when the screen is popped. All
/// write operations delegate to [DocumentsNotifier] so the list screen stays
/// in sync automatically.
@riverpod
class DocumentDetailNotifier extends _$DocumentDetailNotifier {
  @override
  Future<Document> build(String id) async {
    return ref.read(documentsProvider.notifier).getById(id);
  }

  // ── Signed URL ──────────────────────────────────────────────────────────────

  /// Generates a signed URL for the document file valid for 1 hour.
  ///
  /// Returns null when [Document.filePath] is empty or the storage call fails.
  Future<String?> getSignedUrl() async {
    final document = state.value;
    if (document == null || document.filePath.isEmpty) return null;

    final response = await SupabaseService.client.storage
        .from('documents')
        .createSignedUrl(document.filePath, 3600);

    return response;
  }

  // ── Mutations ───────────────────────────────────────────────────────────────

  /// Updates mutable metadata fields and refreshes the detail state.
  Future<void> updateDocument(Map<String, dynamic> changes) async {
    final document = state.value;
    if (document == null) return;

    await ref.read(documentsProvider.notifier).updateDocument(document.id, changes);

    // Re-fetch so the detail screen shows the persisted values.
    ref.invalidateSelf();
    await future;
  }

  /// Soft-deletes the document (sets deleted_at).
  ///
  /// Does NOT navigate back — the caller is responsible for popping after
  /// this completes. The list provider is invalidated by [DocumentsNotifier].
  Future<void> softDelete() async {
    final document = state.value;
    if (document == null) return;

    await ref.read(documentsProvider.notifier).softDelete(document.id);
  }

  /// Restores a soft-deleted document (clears deleted_at).
  ///
  /// Used by the undo-delete flow when the user taps UNDO within 5 seconds.
  Future<void> restore() async {
    final document = state.value;
    if (document == null) return;

    await ref.read(documentsProvider.notifier).restore(document.id);

    // Re-fetch to confirm the restored state.
    ref.invalidateSelf();
    await future;
  }
}
