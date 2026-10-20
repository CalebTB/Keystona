import 'package:flutter/foundation.dart';

/// Everything a renewal writes onto the existing document.
class DocumentRenewalRequest {
  const DocumentRenewalRequest({
    required this.documentId,
    required this.mimeType,
    required this.name,
    required this.categoryId,
    required this.pageCount,
    required this.tags,
    required this.expirationDate,
    this.notes,
    this.linkedSystemId,
    this.linkedApplianceId,
  });

  final String documentId;
  final String mimeType;
  final String name;
  final String categoryId;
  final int pageCount;
  final List<String> tags;

  /// The new end date. Required: that is what a renewal is for.
  final DateTime expirationDate;
  final String? notes;
  final String? linkedSystemId;
  final String? linkedApplianceId;
}

/// The storage and database steps of a renewal. A seam so the order of the
/// steps is tested with a fake and never reaches Supabase.
abstract interface class DocumentRenewalStore {
  /// The paths of the files the document has now.
  Future<({String filePath, String? thumbnailPath})> currentFiles(
    String documentId,
  );

  /// Stores [bytes] at the new [path] in the private bucket.
  Future<void> putFile(String path, Uint8List bytes, String mimeType);

  /// Plain UPDATE of the document row.
  Future<void> updateRow(String documentId, Map<String, dynamic> changes);

  /// Deletes stored objects.
  Future<void> removeFiles(List<String> paths);

  /// Asks for the new file to be read. Secondary: never throws.
  void requestOcr(String documentId);
}

/// Renews a document in place: the new file and end date go onto the SAME row.
///
/// Order, so a failure never loses the document:
///  1. the new file is stored at a NEW path (the old object is never
///     overwritten);
///  2. the row is updated;
///  3. only then is the old object removed, best effort and silent.
/// When step 2 fails the new object is removed and the document is untouched.
class DocumentRenewer {
  const DocumentRenewer(this._store, {required this.newPath});

  final DocumentRenewalStore _store;

  /// The storage path for the new file, given the old file's path (so it
  /// stays in the same user and property folder).
  final String Function(String oldPath, String mimeType) newPath;

  /// The columns written to the document row. File fields are replaced, the
  /// reminder flags start over, everything not listed (id, created_at,
  /// property_id, user_id, metadata, deleted_at) is left alone.
  static Map<String, dynamic> changes(
    DocumentRenewalRequest request, {
    required String path,
    required int sizeBytes,
  }) {
    final notes = request.notes?.trim();
    return {
      'name': request.name.trim(),
      'category_id': request.categoryId,
      'file_path': path,
      'thumbnail_path': null,
      'file_size_bytes': sizeBytes,
      'mime_type': request.mimeType,
      'page_count': request.pageCount,
      'ocr_text': null,
      'ocr_status': 'pending',
      'expiration_date': _dateOnly(request.expirationDate),
      'expiration_reminded_90': false,
      'expiration_reminded_30': false,
      'expiration_reminded_7': false,
      'notes': (notes == null || notes.isEmpty) ? null : notes,
      'linked_system_id': request.linkedSystemId,
      'linked_appliance_id': request.linkedApplianceId,
      'tags': request.tags,
    };
  }

  /// Runs the renewal. Throws when the file could not be stored or the row
  /// could not be updated; in both cases the document is as it was.
  Future<void> renew(
    DocumentRenewalRequest request,
    Uint8List bytes, {
    required void Function(double progress) onProgress,
  }) async {
    onProgress(0.1);
    final old = await _store.currentFiles(request.documentId);

    onProgress(0.3);
    final path = newPath(old.filePath, request.mimeType);
    await _store.putFile(path, bytes, request.mimeType);

    onProgress(0.8);
    try {
      await _store.updateRow(
        request.documentId,
        changes(request, path: path, sizeBytes: bytes.length),
      );
    } catch (_) {
      await _quietly(() => _store.removeFiles([path]));
      rethrow;
    }

    _store.requestOcr(request.documentId);
    await _quietly(
      () => _store.removeFiles([
        old.filePath,
        if (old.thumbnailPath != null) old.thumbnailPath!,
      ]),
    );
    onProgress(1);
  }

  /// Runs a cleanup step that must never block or show an error. Only the
  /// exception type is logged: paths and names are PII.
  Future<void> _quietly(Future<void> Function() step) async {
    try {
      await step();
    } catch (e) {
      debugPrint('Renewal cleanup failed: ${e.runtimeType}');
    }
  }

  /// DATE columns take `YYYY-MM-DD`, not a timestamp.
  static String _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day).toIso8601String().split('T').first;
}
