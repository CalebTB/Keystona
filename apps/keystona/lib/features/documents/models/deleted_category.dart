import 'document_category.dart';

/// What a category delete removed, so the Undo snackbar can put it back.
class DeletedCategory {
  const DeletedCategory({
    required this.category,
    required this.movedDocumentIds,
    required this.movedToCategoryId,
  });

  final DocumentCategory category;

  /// Documents that were moved out of [category].
  final List<String> movedDocumentIds;

  /// The category they were moved into.
  final String movedToCategoryId;
}
