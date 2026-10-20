import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/theme/aurora_docs_b.dart';
import '../../../services/providers/service_providers.dart';
import '../models/document_category.dart';
import '../models/document_ocr.dart';
import '../models/document_scan.dart';
import '../models/document_tags.dart';
import '../models/document_upload_state.dart';
import '../models/renewal_source.dart';
import '../../subscription/providers/subscription_provider.dart';
import '../services/document_renewer.dart';
import '../services/document_upload_repository.dart';
import 'document_categories_provider.dart';
import 'document_detail_provider.dart';
import 'document_renewal_provider.dart';
import 'document_upload_services_provider.dart';
import 'document_removal.dart';
import 'scan_reading_provider.dart';

part 'document_upload_provider.g.dart';

/// State of the add-a-document flow: the picked file, the form, and the save.
///
/// Kept alive so the file picked in the add-from sheet is still here when the
/// form opens a moment later. The Docs tab invalidates it when a new add
/// starts, and the form invalidates it when it closes.
@Riverpod(keepAlive: true)
class DocumentUploadNotifier extends _$DocumentUploadNotifier {
  @override
  DocumentUploadState build() {
    // Smart scan told to keep going in the background: fill the form in when
    // it lands, unless the user got there first.
    ref.listen(scanReadingProvider, (previous, next) {
      final landed = next.isDone && !(previous?.isDone ?? false);
      if (landed && state.hasFile && state.scanFilled.isEmpty) {
        applyScanResult(next.result);
      }
    });
    return const DocumentUploadState();
  }

  // ── File ───────────────────────────────────────────────────────────────────

  /// A file from the library or the Files app.
  void setPickedFile({
    required File file,
    required String mimeType,
    required int sizeBytes,
    required String name,
    File? previewFile,
  }) {
    // A renewal keeps the name it started with; the file's name is not it.
    state = _withoutFile().copyWith(
      file: file,
      mimeType: mimeType,
      fileSizeBytes: sizeBytes,
      fileLabel: name,
      previewFile: previewFile,
      name: state.isRenewal ? state.name : name,
    );
  }

  /// The pages from the camera, combined into one file.
  void setScan(ScanOutcome scan, {required String label}) {
    state = _withoutFile().copyWith(
      file: scan.file,
      mimeType: scan.mimeType,
      fileSizeBytes: scan.sizeBytes,
      pageCount: scan.pageCount,
      fileLabel: label,
      previewFile: scan.previewFile,
    );
  }

  /// "Remove file": back to an empty form. A renewal keeps what it carried
  /// over from the old document.
  void removeFile() => state = _withoutFile();

  /// The form with no file. An ordinary add starts over; a renewal keeps its
  /// fields so picking a file never wipes them.
  DocumentUploadState _withoutFile() {
    if (!state.isRenewal) return const DocumentUploadState();
    return state.copyWith(
      file: null,
      mimeType: null,
      fileSizeBytes: null,
      pageCount: 1,
      fileLabel: '',
      previewFile: null,
      expirationFoundOnPage: null,
      scanFilled: const {},
      scanDetailCount: 0,
    );
  }

  /// Starts the form as a renewal of [source]: name, category, tags, notes and
  /// link come from the existing document, the new end date is left empty and
  /// required. Smart scan never overwrites what was carried over. Does nothing
  /// when this renewal is already applied.
  void applyRenewal(RenewalSource source) {
    if (state.renewal?.id == source.id) return;
    state = state.copyWith(
      renewal: source,
      name: source.name,
      categoryId: source.categoryId,
      categoryName: source.categoryName,
      tags: source.tags,
      link: source.link,
      notes: source.notes,
      expiresChoice: true,
      expirationDate: null,
      edited: {
        ...state.edited,
        UploadField.name,
        UploadField.category,
        UploadField.link,
      },
    );
  }

  /// Fills the form from what smart scan found, leaving anything the user has
  /// already changed alone.
  Future<void> applyScanResult(OcrResult result) async {
    List<DocumentCategory> categories = const [];
    try {
      categories = await ref.read(documentCategoriesProvider.future);
    } catch (_) {
      // No categories: the category is simply not filled in.
    }
    if (!ref.mounted) return;
    var next = state;
    final filled = <UploadField>{...next.scanFilled};
    bool open(UploadField f) => !next.edited.contains(f);

    if (result.name != null && open(UploadField.name)) {
      next = next.copyWith(name: result.name!);
      filled.add(UploadField.name);
    }
    final category = _match(categories, result.categoryName);
    if (category != null && open(UploadField.category)) {
      next = next.copyWith(
        categoryId: category.id,
        categoryName: category.name,
      );
      filled.add(UploadField.category);
    }
    if (result.expirationDate != null && open(UploadField.expiration)) {
      next = next.copyWith(
        expirationDate: result.expirationDate,
        expirationFoundOnPage: result.expirationPage,
        expiresChoice: true,
      );
      filled.add(UploadField.expiration);
    }
    final link = result.link;
    if (link != null && open(UploadField.link)) {
      next = next.copyWith(
        link: (
          id: link.id,
          isAppliance: link.isAppliance,
          name: link.name,
          detail: link.matchedOn == null ? null : 'Matched ${link.matchedOn}',
        ),
      );
      filled.add(UploadField.link);
    }
    state = next.copyWith(
      scanFilled: filled,
      scanDetailCount: result.detailCount,
    );
  }

  DocumentCategory? _match(List<DocumentCategory> all, String? name) {
    if (name == null) return null;
    final wanted = name.trim().toLowerCase();
    for (final c in all) {
      if (c.name.toLowerCase() == wanted) return c;
    }
    return null;
  }

  // ── Fields ─────────────────────────────────────────────────────────────────

  /// Picks the category the form starts on once categories are known.
  void useDefaultCategory(List<DocumentCategory> categories) {
    if (state.categoryId != null || categories.isEmpty) return;
    final fallback = categories.firstWhere(
      (c) => c.name.toLowerCase() == 'other',
      orElse: () => categories.first,
    );
    state = state.copyWith(
      categoryId: fallback.id,
      categoryName: fallback.name,
    );
  }

  void setName(String value) =>
      state = _touch(state.copyWith(name: value), UploadField.name);

  void selectCategory(DocumentCategory category) => state = _touch(
    state.copyWith(categoryId: category.id, categoryName: category.name),
    UploadField.category,
  );

  /// "It expires" switch. A renewal always expires: it exists to set the new
  /// end date, so the switch cannot clear it.
  void setExpires(bool value) {
    if (state.isRenewal) return;
    state = _touch(
      state.copyWith(
        expiresChoice: value,
        expirationDate: value ? state.expirationDate : null,
      ),
      UploadField.expiration,
    );
  }

  void setExpirationDate(DateTime value) => state = _touch(
    state.copyWith(expirationDate: value),
    UploadField.expiration,
  );

  void setLink(UploadLink? link) =>
      state = _touch(state.copyWith(link: link), UploadField.link);

  void setNotes(String value) => state = state.copyWith(notes: value);

  /// Adds a tag: trimmed, not empty, not a repeat, within the limits.
  /// Returns false when it was not added.
  bool addTag(String raw) {
    final next = DocumentTags.adding(
      state.tags,
      raw,
      max: AuroraUploadRules.maxTags,
      maxLength: AuroraUploadRules.maxTagLength,
    );
    if (next == null) return false;
    state = state.copyWith(tags: next);
    return true;
  }

  void removeTag(String tag) =>
      state = state.copyWith(tags: [...state.tags]..remove(tag));

  /// A change by the user: the field no longer shows smart scan's value.
  DocumentUploadState _touch(DocumentUploadState next, UploadField field) =>
      next.copyWith(
        edited: {...next.edited, field},
        scanFilled: {...next.scanFilled}..remove(field),
      );

  // ── Save ───────────────────────────────────────────────────────────────────

  /// Saves the form. An ordinary add uploads the file and creates a document;
  /// a renewal puts the new file and end date on the existing document. On
  /// failure the form stays as it was, with [DocumentUploadState.failure] set,
  /// so Save can be tried again.
  Future<void> submit() async {
    final file = state.file;
    final categoryId = state.categoryId;
    if (!state.canSave ||
        state.isSaving ||
        file == null ||
        categoryId == null) {
      return;
    }
    final renewal = state.renewal;
    final link = state.link;
    final systemId = link != null && !link.isAppliance ? link.id : null;
    final applianceId = link != null && link.isAppliance ? link.id : null;
    final mimeType = state.mimeType ?? 'application/octet-stream';
    void onProgress(double progress) {
      if (ref.mounted) state = state.copyWith(progress: progress);
    }

    // Read before the first await: the screen may unmount during the save.
    final renewals = ref.read(documentRenewalRepositoryProvider);
    final uploads = ref.read(documentUploadRepositoryProvider);
    final enforceLimit = !ref.read(isPremiumProvider);
    final expirationDate = state.expires ? state.expirationDate : null;

    state = state.copyWith(
      phase: UploadPhase.uploading,
      progress: 0,
      failure: null,
    );
    try {
      final String savedId;
      if (renewal == null) {
        final saved = await uploads.upload(
          DocumentUploadRequest(
            file: file,
            mimeType: mimeType,
            name: state.name,
            categoryId: categoryId,
            pageCount: state.pageCount,
            tags: state.tags,
            expirationDate: expirationDate,
            notes: state.notes,
            linkedSystemId: systemId,
            linkedApplianceId: applianceId,
          ),
          enforceFreeLimit: enforceLimit,
          onProgress: onProgress,
        );
        savedId = saved.id;
      } else {
        await renewals.renew(
          DocumentRenewalRequest(
            documentId: renewal.id,
            mimeType: mimeType,
            name: state.name,
            categoryId: categoryId,
            pageCount: state.pageCount,
            tags: state.tags,
            expirationDate: expirationDate!,
            notes: state.notes,
            linkedSystemId: systemId,
            linkedApplianceId: applianceId,
          ),
          file,
          onProgress: onProgress,
        );
        savedId = renewal.id;
      }
      if (!ref.mounted) return;
      state = state.copyWith(
        phase: UploadPhase.success,
        progress: 1,
        savedDocumentId: savedId,
      );
      invalidateDocumentLists(ref.invalidate);
      if (renewal != null) ref.invalidate(documentDetailProvider(renewal.id));
    } on DocumentLimitException {
      if (!ref.mounted) return;
      state = state.copyWith(
        phase: UploadPhase.editing,
        failure: UploadFailure.limitReached,
      );
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(
        phase: UploadPhase.editing,
        failure: UploadFailure.generic,
      );
    }
  }

  /// Clears a shown failure so it is not reported twice.
  void clearFailure() => state = state.copyWith(failure: null);
}
