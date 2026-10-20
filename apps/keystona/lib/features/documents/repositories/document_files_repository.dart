import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Private-bucket file access for documents. Files are never public: every
/// view goes through a signed URL or an authenticated download.
abstract interface class DocumentFilesRepository {
  /// A signed URL for [path], or null when it cannot be created.
  Future<String?> signedUrl(String path);

  /// The raw bytes of the file at [path].
  Future<Uint8List> download(String path);
}

class SupabaseDocumentFilesRepository implements DocumentFilesRepository {
  SupabaseDocumentFilesRepository(this._client);

  final SupabaseClient _client;

  static const String _bucket = 'documents';

  /// Signed URL lifetime.
  static const int signedUrlSeconds = 3600;

  @override
  Future<String?> signedUrl(String path) async {
    if (path.isEmpty) return null;
    return _client.storage
        .from(_bucket)
        .createSignedUrl(path, signedUrlSeconds);
  }

  @override
  Future<Uint8List> download(String path) =>
      _client.storage.from(_bucket).download(path);
}
