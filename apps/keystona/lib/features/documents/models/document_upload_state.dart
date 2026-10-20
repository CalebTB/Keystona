import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/theme/aurora_docs_b.dart';
import 'document.dart';
import 'renewal_source.dart';

part 'document_upload_state.freezed.dart';

/// Where the new-document form is.
enum UploadPhase {
  /// Filling in the form.
  editing,

  /// Saving: the file is on its way up.
  uploading,

  /// Saved.
  success,
}

/// A field smart scan can fill in. The form edges these in cobalt until the
/// user changes them.
enum UploadField { name, category, expiration, link }

/// Why a save did not go through.
enum UploadFailure {
  /// Network or server trouble: offer a retry.
  generic,

  /// The free plan is full: offer the upgrade.
  limitReached,
}

/// What the document is linked to: a system or an appliance.
typedef UploadLink = ({
  String id,
  bool isAppliance,
  String name,
  String? detail,
});

/// Ephemeral state of the add-a-document flow. Not serialised.
@freezed
abstract class DocumentUploadState with _$DocumentUploadState {
  const DocumentUploadState._();

  const factory DocumentUploadState({
    @Default(UploadPhase.editing) UploadPhase phase,

    // ── File ───────────────────────────────────────────────────────────────
    File? file,
    String? mimeType,
    int? fileSizeBytes,
    @Default(1) int pageCount,

    /// "Scan · 3 pages" or the picked file's name.
    @Default('') String fileLabel,

    /// First page image for the thumbnail. Null for a picked PDF.
    File? previewFile,

    // ── Fields ─────────────────────────────────────────────────────────────
    @Default('') String name,
    String? categoryId,
    @Default('') String categoryName,

    /// The user's choice on "It expires"; null follows the category default.
    bool? expiresChoice,
    DateTime? expirationDate,

    /// 1-based page the expiry date was found on (smart scan).
    int? expirationFoundOnPage,
    UploadLink? link,
    @Default(<String>[]) List<String> tags,
    @Default('') String notes,

    // ── Smart scan ─────────────────────────────────────────────────────────
    /// Fields still showing smart scan's value.
    @Default(<UploadField>{}) Set<UploadField> scanFilled,

    /// Fields the user has touched; smart scan never overwrites these.
    @Default(<UploadField>{}) Set<UploadField> edited,

    /// "Smart scan read N details."
    @Default(0) int scanDetailCount,

    // ── Save ───────────────────────────────────────────────────────────────
    @Default(0.0) double progress,
    UploadFailure? failure,
    Document? uploadedDocument,

    // ── Renewal ────────────────────────────────────────────────────────────
    /// The document this one renews; null for an ordinary new document.
    RenewalSource? renewal,

    /// The new document was saved but the old one could not be marked
    /// replaced.
    @Default(false) bool renewalMarkFailed,
  }) = _DocumentUploadState;

  bool get hasFile => file != null;

  bool get isRenewal => renewal != null;

  /// "It expires": the user's choice, else on for categories that usually
  /// expire.
  bool get expires =>
      expiresChoice ??
      AuroraUploadRules.expiringCategories.contains(categoryName.toLowerCase());

  bool get isSaving => phase == UploadPhase.uploading;

  /// The Save pill is live: a file, a name, a category and, when it expires,
  /// a date.
  bool get canSave =>
      hasFile &&
      name.trim().isNotEmpty &&
      categoryId != null &&
      (!expires || expirationDate != null);
}
