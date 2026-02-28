import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'document.dart';

part 'document_upload_state.freezed.dart';

/// The step the upload wizard is currently showing.
enum DocumentUploadStep {
  /// Step 1 — user selects a category (and optionally a document type).
  category,

  /// Step 2 — user enters name, expiration date, and notes.
  metadata,

  /// Step 3 — upload in progress; transitions to [success] or shows error.
  uploading,

  /// Upload finished — shows confirmation card with "View Document" option.
  success,
}

/// Ephemeral wizard state for the document upload flow.
///
/// Not serialised — kept in-memory only.
@freezed
abstract class DocumentUploadState with _$DocumentUploadState {
  const factory DocumentUploadState({
    /// Which step the wizard is showing.
    @Default(DocumentUploadStep.category) DocumentUploadStep step,

    /// The file the user has picked. Null only during source-picker display.
    File? file,

    /// MIME type inferred from the file extension.
    String? mimeType,

    /// File name without extension — pre-filled into the name field.
    @Default('') String suggestedName,

    // ── Step 1 fields ────────────────────────────────────────────────────────

    /// Selected category ID. Required before advancing to step 2.
    String? categoryId,

    /// Optional document type ID within the category.
    String? documentTypeId,

    // ── Step 2 fields ────────────────────────────────────────────────────────

    /// Document name. Required. Auto-filled from [suggestedName].
    @Default('') String name,

    /// Optional expiration date. Used for expiration badges.
    DateTime? expirationDate,

    /// Optional freeform notes.
    String? notes,

    // ── Step 3 fields ────────────────────────────────────────────────────────

    /// Upload progress 0.0–1.0.
    @Default(0.0) double uploadProgress,

    /// Set after a successful upload. Used to build the success card.
    Document? uploadedDocument,

    /// Set when an upload error occurs.
    String? errorMessage,
  }) = _DocumentUploadState;
}
