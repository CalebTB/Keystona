import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Preparing a picked file for the private `documents` bucket: shrinking big
/// photos and choosing the stored extension. Shared by adding a document and
/// renewing one.
abstract final class UploadFiles {
  /// Photos larger than this are compressed before upload.
  static const int _compressAboveBytes = 2 * 1024 * 1024;
  static const int _compressQuality = 80;
  static const int _compressMaxEdge = 1920;

  /// [file] itself, or a smaller JPEG copy when it is a big photo.
  static Future<File> prepare(File file, String mimeType) async {
    if (mimeType.startsWith('application/')) return file;
    if (await file.length() <= _compressAboveBytes) return file;
    final dir = await getTemporaryDirectory();
    final target =
        '${dir.path}/upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final shrunk = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      target,
      quality: _compressQuality,
      minWidth: _compressMaxEdge,
      minHeight: _compressMaxEdge,
    );
    return shrunk == null ? file : File(shrunk.path);
  }

  /// `.pdf`, `.jpg`, ... for a MIME type; empty when unfamiliar.
  static String extension(String mime) => switch (mime) {
    'application/pdf' => '.pdf',
    'image/jpeg' => '.jpg',
    'image/png' => '.png',
    'image/heic' => '.heic',
    _ => '',
  };
}
