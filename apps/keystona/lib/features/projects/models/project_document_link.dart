// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_document_link.freezed.dart';
part 'project_document_link.g.dart';

/// A row from the `project_documents` join table, denormalized with document info.
@freezed
abstract class ProjectDocumentLink with _$ProjectDocumentLink {
  const factory ProjectDocumentLink({
    required String id,
    required String projectId,
    required String documentId,
    required String linkType,
    required String linkedBy,
    required DateTime createdAt,
    // Denormalized — not in DB row, assembled by provider.
    @Default('') String documentName,
    String? documentTypeName,
  }) = _ProjectDocumentLink;

  factory ProjectDocumentLink.fromJson(Map<String, dynamic> json) =>
      _$ProjectDocumentLinkFromJson(json);
}

/// Link type values and display labels for the `project_doc_link_type` DB enum.
abstract final class DocumentLinkTypes {
  static const all = [
    (value: 'receipt', label: 'Receipt'),
    (value: 'permit', label: 'Permit'),
    (value: 'contract', label: 'Contract'),
    (value: 'invoice', label: 'Invoice'),
    (value: 'warranty', label: 'Warranty'),
    (value: 'general', label: 'General'),
  ];

  static String labelFor(String value) => all
      .firstWhere((t) => t.value == value,
          orElse: () => (value: value, label: value))
      .label;
}
