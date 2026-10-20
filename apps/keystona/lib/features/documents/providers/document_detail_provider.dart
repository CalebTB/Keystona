import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/document.dart';
import '../models/document_edit.dart';
import 'document_repositories_provider.dart';
import 'document_removal.dart';
import 'documents_provider.dart';

part 'document_detail_provider.g.dart';

/// State for the Document Detail screen, keyed by document [id] and
/// auto-disposed when the screen is popped. Edits go through
/// [DocumentsNotifier] and then refetch every list built from documents.
/// Delete and Undo are `deleteDocument` / `restoreDocument`.
@riverpod
class DocumentDetailNotifier extends _$DocumentDetailNotifier {
  @override
  Future<Document> build(String id) =>
      ref.read(documentsProvider.notifier).getById(id);

  /// A signed URL for the file, valid for an hour. Null when there is no file
  /// or the URL cannot be created.
  Future<String?> signedUrl() async {
    final document = state.value;
    if (document == null) return null;
    return ref.read(documentFilesRepositoryProvider).signedUrl(document.filePath);
  }

  /// Saves edits. The screen shows them immediately; they are rolled back
  /// (and the error rethrown) if the write fails.
  Future<void> saveEdits(DocumentEdit edit) async {
    final current = state.value;
    if (current == null) return;
    final documents = ref.read(documentsProvider.notifier);

    state = AsyncData(
      current.copyWith(
        name: edit.name,
        categoryId: edit.categoryId,
        tags: edit.tags,
        expirationDate: edit.expirationDate,
        notes: edit.notes,
      ),
    );

    try {
      await documents.updateDocument(current.id, edit.toChanges());
    } catch (_) {
      if (ref.mounted) state = AsyncData(current);
      rethrow;
    }

    if (!ref.mounted) return;
    invalidateDocumentLists(ref.invalidate);
    // Re-fetch so the joined category and timestamps are the persisted ones.
    ref.invalidateSelf();
    await future;
  }

  /// Placeholder for swapping the stored file.
  ///
  /// [#N] backend: needs a storage upload + `documents.file_path` update.
  Future<void> replaceFile() async {
    throw UnimplementedError('replaceFile() implemented by issue #N');
  }
}
