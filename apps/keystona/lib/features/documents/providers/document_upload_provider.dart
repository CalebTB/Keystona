import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import 'package:uuid/uuid.dart';

import '../../../services/supabase_service.dart';
import '../models/document.dart';
import '../models/document_upload_state.dart';
import 'documents_provider.dart';

part 'document_upload_provider.g.dart';

const _freeDocumentLimit = 25;

/// Manages the document upload wizard state and the actual upload operation.
///
/// Lifecycle: created when the upload screen opens, disposed on pop.
/// The [DocumentsNotifier] list is invalidated after a successful upload.
///
/// Step flow:
///   category → metadata → uploading → success
@riverpod
class DocumentUploadNotifier extends _$DocumentUploadNotifier {
  @override
  DocumentUploadState build() => const DocumentUploadState();

  // ── File ─────────────────────────────────────────────────────────────────

  /// Called from the upload screen after the user picks a file.
  ///
  /// Stores the file and derived metadata, then starts at [DocumentUploadStep.category].
  void setFile(File file, String mimeType, String suggestedName) {
    state = DocumentUploadState(
      file: file,
      mimeType: mimeType,
      suggestedName: suggestedName,
      name: suggestedName,
    );
  }

  // ── Step 1 ───────────────────────────────────────────────────────────────

  /// Stores the selected category and advances to metadata step.
  void selectCategory(String categoryId, {String? documentTypeId}) {
    state = state.copyWith(
      categoryId: categoryId,
      documentTypeId: documentTypeId,
    );
  }

  void advanceToMetadata() {
    state = state.copyWith(step: DocumentUploadStep.metadata);
  }

  // ── Step 2 ───────────────────────────────────────────────────────────────

  void setName(String value) => state = state.copyWith(name: value);
  void setExpirationDate(DateTime? value) =>
      state = state.copyWith(expirationDate: value);
  void setNotes(String? value) => state = state.copyWith(notes: value);

  // ── Navigation ───────────────────────────────────────────────────────────

  void goBack() {
    switch (state.step) {
      case DocumentUploadStep.metadata:
        state = state.copyWith(step: DocumentUploadStep.category);
      case DocumentUploadStep.uploading:
      case DocumentUploadStep.success:
      case DocumentUploadStep.category:
        break;
    }
  }

  // ── Upload ───────────────────────────────────────────────────────────────

  /// Validates metadata, checks the free tier limit, then uploads the file.
  ///
  /// On success, invalidates [DocumentsNotifier] so the list refreshes.
  /// On failure, sets [DocumentUploadState.errorMessage] and stays on the
  /// progress step so the user can retry.
  Future<void> upload() async {
    final file = state.file;
    if (file == null) return;

    state = state.copyWith(
      step: DocumentUploadStep.uploading,
      errorMessage: null,
      uploadProgress: 0.0,
    );

    try {
      final client = SupabaseService.client;
      final user = client.auth.currentUser;
      if (user == null) throw Exception('Not signed in');

      // ── 1. Resolve property ──────────────────────────────────────────────
      state = state.copyWith(uploadProgress: 0.05);
      final propertyRow = await client
          .from('properties')
          .select('id')
          .eq('user_id', user.id)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (propertyRow == null) throw Exception('No property found');
      final propertyId = propertyRow['id'] as String;

      // ── 2. Free-tier gate ─────────────────────────────────────────────────
      state = state.copyWith(uploadProgress: 0.1);
      final countResponse = await client
          .from('documents')
          .select('id')
          .eq('property_id', propertyId)
          .isFilter('deleted_at', null);

      if (countResponse.length >= _freeDocumentLimit) {
        throw _FreeTierException();
      }

      // ── 3. Compress image if needed ──────────────────────────────────────
      state = state.copyWith(uploadProgress: 0.2);
      final uploadFile = await _prepareFile(file, state.mimeType);

      // ── 4. Upload to Supabase Storage ────────────────────────────────────
      state = state.copyWith(uploadProgress: 0.4);
      final ext = _extensionFromMime(state.mimeType);
      final storagePath =
          '${user.id}/$propertyId/${const Uuid().v4()}$ext';

      final bytes = await uploadFile.readAsBytes();
      await client.storage
          .from('documents')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(contentType: state.mimeType ?? 'application/octet-stream'),
          );

      // ── 5. Insert document row ────────────────────────────────────────────
      state = state.copyWith(uploadProgress: 0.8);
      final trimmedNotes =
          state.notes?.trim().isEmpty == true ? null : state.notes?.trim();

      final response = await client
          .from('documents')
          .insert({
            'property_id': propertyId,
            'user_id': user.id,
            'name': state.name.trim(),
            'category_id': state.categoryId,
            'document_type_id': state.documentTypeId,
            'file_path': storagePath,
            'file_size_bytes': await file.length(),
            'mime_type': state.mimeType,
            'expiration_date': state.expirationDate?.toIso8601String(),
            'notes': trimmedNotes,
            'ocr_status': 'pending',
          })
          .select(
            'id, name, category_id, document_type_id, created_at, updated_at, '
            'expiration_date, thumbnail_path, file_path, file_size_bytes, '
            'mime_type, page_count, ocr_status, notes, linked_system_id, '
            'linked_appliance_id',
          )
          .single();

      // ── 6. Trigger OCR (fire-and-forget) ─────────────────────────────────
      _triggerOcr(response['id'] as String);

      // ── 7. Success ────────────────────────────────────────────────────────
      state = state.copyWith(uploadProgress: 1.0);

      final doc = Document.fromJson({
        ...response,
        'user_id': user.id,
        'property_id': propertyId,
        'metadata': <String, dynamic>{},
      });

      state = state.copyWith(
        step: DocumentUploadStep.success,
        uploadedDocument: doc,
      );

      // Refresh the documents list.
      ref.invalidate(documentsProvider);
    } on _FreeTierException {
      state = state.copyWith(
        step: DocumentUploadStep.metadata,
        errorMessage: 'free_tier',
      );
    } catch (_) {
      state = state.copyWith(
        step: DocumentUploadStep.uploading,
        errorMessage: 'Upload failed. Please try again.',
      );
    }
  }

  /// Retries a failed upload. Resets progress and re-runs [upload].
  Future<void> retryUpload() async {
    state = state.copyWith(errorMessage: null, uploadProgress: 0.0);
    await upload();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Compresses HEIC/JPEG images. Returns original file for PDFs.
  Future<File> _prepareFile(File file, String? mimeType) async {
    if (mimeType == null || mimeType.startsWith('application/')) return file;

    final bytes = await file.length();
    const maxBytes = 2 * 1024 * 1024; // 2 MB
    if (bytes <= maxBytes) return file;

    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/upload_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final xFile = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 80,
      minWidth: 1920,
      minHeight: 1920,
    );

    return xFile != null ? File(xFile.path) : file;
  }

  String _extensionFromMime(String? mime) {
    switch (mime) {
      case 'application/pdf':
        return '.pdf';
      case 'image/jpeg':
        return '.jpg';
      case 'image/png':
        return '.png';
      case 'image/heic':
        return '.heic';
      default:
        return '';
    }
  }

  /// Fire-and-forget OCR trigger via Supabase Edge Function.
  void _triggerOcr(String documentId) {
    SupabaseService.client.functions
        .invoke('process-document-ocr', body: {'document_id': documentId})
        .ignore();
  }
}

class _FreeTierException implements Exception {}
