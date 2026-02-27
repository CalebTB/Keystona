import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Handles all Supabase Storage bucket operations.
///
/// Always use signed URLs for file access — never construct public URLs
/// directly. All paths must follow the convention:
/// `{userId}/{propertyId}/{filename}` to match RLS bucket policies.
class StorageService {
  final _client = SupabaseService.client;

  /// Uploads [file] to [bucket] at [path] and returns the storage path.
  ///
  /// [path] example: `'{userId}/{propertyId}/invoice.pdf'`
  /// Set [contentType] explicitly for non-image files (e.g. `'application/pdf'`).
  ///
  /// Throws [StorageException] on failure.
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required File file,
    String? contentType,
  }) async {
    await _client.storage.from(bucket).upload(
          path,
          file,
          fileOptions: contentType != null
              ? FileOptions(contentType: contentType)
              : const FileOptions(),
        );
    return path;
  }

  /// Returns a time-limited signed URL for [path] in [bucket].
  ///
  /// [expiresInSeconds] defaults to 3600 (1 hour).
  /// Throws [StorageException] if the path does not exist.
  Future<String> getSignedUrl({
    required String bucket,
    required String path,
    int expiresInSeconds = 3600,
  }) async {
    return _client.storage.from(bucket).createSignedUrl(
          path,
          expiresInSeconds,
        );
  }

  /// Permanently deletes the file at [path] in [bucket].
  ///
  /// Throws [StorageException] if the file does not exist or access is denied.
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    await _client.storage.from(bucket).remove([path]);
  }
}
