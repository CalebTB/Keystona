import 'package:freezed_annotation/freezed_annotation.dart';

import 'document_category.dart';
import 'document_type.dart';

part 'document.freezed.dart';
part 'document.g.dart';

/// A document stored in the homeowner's Document Vault.
///
/// This model covers all fields required by issues #20–#26. Fields that are
/// not yet used by this screen are documented with the issue that will use them.
@freezed
abstract class Document with _$Document {
  const factory Document({
    required String id,
    required String propertyId,
    required String userId,

    // ── Classification ────────────────────────────────────────────────────────

    /// Display name of the document. [#20] list card, [#23] search.
    required String name,

    /// Foreign key to [DocumentCategory]. [#20] filter chip.
    required String categoryId,

    /// Foreign key to [DocumentType]. Null when not yet classified.
    /// [#21] upload form, [#22] detail screen.
    String? documentTypeId,

    // ── File ─────────────────────────────────────────────────────────────────

    /// Storage path for the primary file. [#22] preview.
    required String filePath,

    /// Storage path for the generated thumbnail. [#20] card thumbnail.
    /// Set by the storage Edge Function (#26).
    String? thumbnailPath,

    /// Original file size in bytes. [#22] detail screen.
    int? fileSizeBytes,

    /// MIME type string (e.g. 'application/pdf', 'image/jpeg'). [#22] viewer.
    String? mimeType,

    /// Number of pages — only set for PDF documents. [#22] detail screen.
    int? pageCount,

    // ── OCR ──────────────────────────────────────────────────────────────────

    /// Full extracted text. [#23] search snippet. Set by pipeline (#26).
    String? ocrText,

    /// Processing status: pending | processing | complete | failed.
    @Default('pending') String ocrStatus,

    // ── Metadata ─────────────────────────────────────────────────────────────

    /// Type-specific structured metadata keyed by the [DocumentType.metadataSchema].
    /// [#21] upload form, [#22] display.
    @Default({}) Map<String, dynamic> metadata,

    // ── Expiration ───────────────────────────────────────────────────────────

    /// Date when this document expires. [#20] expiration badge, [#22] detail,
    /// [#24] expiring dashboard widget.
    DateTime? expirationDate,

    // ── Notes & links ────────────────────────────────────────────────────────

    /// Freeform notes entered by the user. [#21] form, [#22] display.
    String? notes,

    /// ID of a linked home system. [#22] linked chip.
    String? linkedSystemId,

    /// ID of a linked appliance. [#22] linked chip.
    String? linkedApplianceId,

    // ── Audit ────────────────────────────────────────────────────────────────

    /// Timestamp of row creation. [#20] sort order.
    required DateTime createdAt,

    /// Timestamp of last update. [#22] display.
    required DateTime updatedAt,

    /// Non-null when soft-deleted. Filtered out by all list queries.
    DateTime? deletedAt,

    // ── Joined fields (not DB columns) ───────────────────────────────────────

    /// Eagerly loaded category. Populated via nested select. [#20] badge.
    DocumentCategory? category,

    /// Eagerly loaded document type. Populated via nested select. [#22] label.
    DocumentType? type,
  }) = _Document;

  factory Document.fromJson(Map<String, dynamic> json) =>
      _$DocumentFromJson(json);
}
