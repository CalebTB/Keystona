import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import 'package:uuid/uuid.dart';

import '../../../services/supabase_service.dart';
import '../models/document_tags.dart';
import '../models/document_upload_state.dart';
import '../models/renewal_source.dart';
import 'document_renewer.dart';
import 'upload_files.dart';

/// Reads the document being renewed and renews it in place.
abstract interface class DocumentRenewalRepository {
  /// What the form starts from. Throws when the document is gone.
  Future<RenewalSource> load(String documentId);

  /// Puts [file] and the new details on the document
  /// [DocumentRenewalRequest.documentId] (same id), then removes the old file.
  /// See [DocumentRenewer] for the order and the failure rules.
  Future<void> renew(
    DocumentRenewalRequest request,
    File file, {
    required void Function(double progress) onProgress,
  });
}

/// [DocumentRenewalRepository] backed by Supabase.
class SupabaseDocumentRenewalRepository implements DocumentRenewalRepository {
  const SupabaseDocumentRenewalRepository();

  @override
  Future<RenewalSource> load(String documentId) async {
    final client = SupabaseService.client;
    final row = await client
        .from('documents')
        .select(
          'id, name, category_id, notes, metadata, tags, linked_system_id, '
          'linked_appliance_id, category:document_categories(name)',
        )
        .eq('id', documentId)
        .isFilter('deleted_at', null)
        .maybeSingle();
    if (row == null) throw StateError('Document not found');

    final metadata = (row['metadata'] as Map<String, dynamic>?) ?? const {};
    return RenewalSource(
      id: row['id'] as String,
      name: row['name'] as String,
      categoryId: row['category_id'] as String,
      categoryName:
          (row['category'] as Map<String, dynamic>?)?['name'] as String? ?? '',
      notes: row['notes'] as String? ?? '',
      tags: DocumentTags.fromRow(
        row['tags'],
        metadata[DocumentTags.legacyMetadataKey],
      ),
      link: await _link(
        systemId: row['linked_system_id'] as String?,
        applianceId: row['linked_appliance_id'] as String?,
      ),
    );
  }

  Future<UploadLink?> _link({String? systemId, String? applianceId}) async {
    final appliance = applianceId != null;
    final id = appliance ? applianceId : systemId;
    if (id == null) return null;
    final row = await SupabaseService.client
        .from(appliance ? 'appliances' : 'systems')
        .select('id, name')
        .eq('id', id)
        .isFilter('deleted_at', null)
        .maybeSingle();
    final name = row?['name'];
    if (name is! String || name.isEmpty) return null;
    return (id: id, isAppliance: appliance, name: name, detail: null);
  }

  @override
  Future<void> renew(
    DocumentRenewalRequest request,
    File file, {
    required void Function(double progress) onProgress,
  }) async {
    final prepared = await UploadFiles.prepare(file, request.mimeType);
    final bytes = await prepared.readAsBytes();
    await DocumentRenewer(
      const _SupabaseRenewalStore(),
      newPath: _newPath,
    ).renew(request, bytes, onProgress: onProgress);
  }

  /// A fresh object in the same `<user>/<property>/` folder as [oldPath].
  static String _newPath(String oldPath, String mimeType) {
    final slash = oldPath.lastIndexOf('/');
    final folder = slash < 0 ? '' : oldPath.substring(0, slash + 1);
    return '$folder${const Uuid().v4()}${UploadFiles.extension(mimeType)}';
  }
}

class _SupabaseRenewalStore implements DocumentRenewalStore {
  const _SupabaseRenewalStore();

  static const String _bucket = 'documents';
  static const String _ocrFunction = 'process-document-ocr';

  @override
  Future<({String filePath, String? thumbnailPath})> currentFiles(
    String documentId,
  ) async {
    final row = await SupabaseService.client
        .from('documents')
        .select('file_path, thumbnail_path')
        .eq('id', documentId)
        .single();
    return (
      filePath: row['file_path'] as String,
      thumbnailPath: row['thumbnail_path'] as String?,
    );
  }

  @override
  Future<void> putFile(String path, Uint8List bytes, String mimeType) =>
      SupabaseService.client.storage
          .from(_bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: mimeType),
          );

  @override
  Future<void> updateRow(String documentId, Map<String, dynamic> changes) =>
      SupabaseService.client
          .from('documents')
          .update(changes)
          .eq('id', documentId);

  @override
  Future<void> removeFiles(List<String> paths) =>
      SupabaseService.client.storage.from(_bucket).remove(paths);

  @override
  void requestOcr(String documentId) {
    try {
      SupabaseService.client.functions
          .invoke(_ocrFunction, body: {'document_id': documentId})
          .ignore();
    } catch (_) {
      // Non-fatal: the document is renewed either way.
    }
  }
}
