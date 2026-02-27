import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_type.freezed.dart';
part 'document_type.g.dart';

/// A document type that belongs to a [DocumentCategory].
///
/// Document types carry an optional [metadataSchema] that defines which
/// typed metadata fields (e.g., policy number, coverage amount) are
/// relevant for documents of that type.
///
/// NOTE: This model is a stub for issue #20. Full implementation is in issue #21.
@freezed
abstract class DocumentType with _$DocumentType {
  const factory DocumentType({
    required String id,
    required String categoryId,
    required String name,
    String? description,
    Map<String, dynamic>? metadataSchema,
    required int sortOrder,
  }) = _DocumentType;

  factory DocumentType.fromJson(Map<String, dynamic> json) =>
      _$DocumentTypeFromJson(json);
}
