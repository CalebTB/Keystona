import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import 'package:uuid/uuid.dart';

import '../../../services/supabase_service.dart';
import '../../subscription/providers/subscription_provider.dart';
import '../models/document.dart';
import '../models/document_quota.dart';
import '../repositories/document_quota_repository.dart';
import 'upload_files.dart';

/// Everything the vault needs to store one new document.
class DocumentUploadRequest {
  const DocumentUploadRequest({
    required this.file,
    required this.mimeType,
    required this.name,
    required this.categoryId,
    required this.pageCount,
    required this.tags,
    this.expirationDate,
    this.notes,
    this.linkedSystemId,
    this.linkedApplianceId,
  });

  final File file;
  final String mimeType;
  final String name;
  final String categoryId;
  final int pageCount;
  final List<String> tags;
  final DateTime? expirationDate;
  final String? notes;
  final String? linkedSystemId;
  final String? linkedApplianceId;
}

/// Stores a new document: file in the private bucket, row in `documents`.
abstract interface class DocumentUploadRepository {
  /// Uploads [request] and returns the saved document.
  ///
  /// [onProgress] gets 0.0 to 1.0. When [enforceFreeLimit] is true and the
  /// property is at the free plan's limit, throws [DocumentLimitException].
  Future<Document> upload(
    DocumentUploadRequest request, {
    required bool enforceFreeLimit,
    required void Function(double progress) onProgress,
  });
}

/// [DocumentUploadRepository] backed by Supabase.
class SupabaseDocumentUploadRepository implements DocumentUploadRepository {
  const SupabaseDocumentUploadRepository({
    this.quota = const SupabaseDocumentQuotaRepository(),
  });

  /// Counts the documents that use up the free plan.
  final DocumentQuotaRepository quota;

  static const String _bucket = 'documents';
  static const String _columns =
      'id, name, category_id, document_type_id, created_at, updated_at, '
      'expiration_date, thumbnail_path, file_path, file_size_bytes, '
      'mime_type, page_count, ocr_status, notes, linked_system_id, '
      'linked_appliance_id, metadata, tags';

  @override
  Future<Document> upload(
    DocumentUploadRequest request, {
    required bool enforceFreeLimit,
    required void Function(double progress) onProgress,
  }) async {
    final client = SupabaseService.client;
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Not signed in');

    // 1. property_id first.
    onProgress(0.05);
    final propertyRow = await client
        .from('properties')
        .select('id')
        .eq('user_id', user.id)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (propertyRow == null) throw StateError('No property found');
    final propertyId = propertyRow['id'] as String;

    // 2. Free plan gate.
    onProgress(0.1);
    if (enforceFreeLimit) {
      final used = await quota.usedFor(propertyId);
      if (DocumentQuota.isFull(used)) {
        throw const DocumentLimitException();
      }
    }

    // 3. Shrink big photos.
    onProgress(0.2);
    final uploadFile = await UploadFiles.prepare(request.file, request.mimeType);

    // 4. File to the private bucket.
    onProgress(0.4);
    final path =
        '${user.id}/$propertyId/${const Uuid().v4()}${UploadFiles.extension(request.mimeType)}';
    await client.storage
        .from(_bucket)
        .uploadBinary(
          path,
          await uploadFile.readAsBytes(),
          fileOptions: FileOptions(contentType: request.mimeType),
        );

    // 5. The row. user_id has no database default.
    onProgress(0.8);
    final response = await client
        .from('documents')
        .insert(
          insertRow(
            request,
            userId: user.id,
            propertyId: propertyId,
            path: path,
            fileSizeBytes: await uploadFile.length(),
          ),
        )
        .select(_columns)
        .single();

    // 6. OCR is secondary: never block the save on it.
    _requestOcr(response['id'] as String);

    onProgress(1);
    return Document.fromJson({
      ...response,
      'user_id': user.id,
      'property_id': propertyId,
    });
  }

  /// The `documents` row for [request]. user_id has no database default, and
  /// tags go in the `tags` TEXT[] column.
  static Map<String, dynamic> insertRow(
    DocumentUploadRequest request, {
    required String userId,
    required String propertyId,
    required String path,
    required int fileSizeBytes,
  }) {
    final notes = request.notes?.trim();
    return {
      'property_id': propertyId,
      'user_id': userId,
      'name': request.name.trim(),
      'category_id': request.categoryId,
      'file_path': path,
      'file_size_bytes': fileSizeBytes,
      'mime_type': request.mimeType,
      'page_count': request.pageCount,
      'expiration_date': request.expirationDate == null
          ? null
          : _dateOnly(request.expirationDate!),
      'notes': (notes == null || notes.isEmpty) ? null : notes,
      'linked_system_id': request.linkedSystemId,
      'linked_appliance_id': request.linkedApplianceId,
      'tags': request.tags,
      'ocr_status': 'pending',
    };
  }

  /// DATE columns take `YYYY-MM-DD`, not a timestamp.
  static String _dateOnly(DateTime date) =>
      date.toIso8601String().split('T').first;

  void _requestOcr(String documentId) {
    try {
      SupabaseService.client.functions
          .invoke('process-document-ocr', body: {'document_id': documentId})
          .ignore();
    } catch (_) {
      // Non-fatal: the document is saved either way.
    }
  }
}
