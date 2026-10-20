import 'dart:io';

import 'document_ocr.dart';

/// The single file produced by the camera: one photo, or several pages
/// combined into a PDF.
class ScanOutcome {
  const ScanOutcome({
    required this.file,
    required this.mimeType,
    required this.sizeBytes,
    required this.pageCount,
    required this.previewFile,
    required this.smart,
  });

  final File file;
  final String mimeType;
  final int sizeBytes;
  final int pageCount;

  /// First page, used as the thumbnail on the form.
  final File previewFile;

  /// True when the pages went through smart scan (premium).
  final bool smart;

  /// Name on the file card: "Scan · 3 pages", or "Photo" for a single
  /// unscanned shot.
  String get label {
    if (pageCount > 1) return 'Scan · $pageCount pages';
    return smart ? 'Scan · 1 page' : 'Photo';
  }
}

/// What the camera hands back: the file and, when smart scan finished while
/// the camera was open, what it found.
class ScanFlowResult {
  const ScanFlowResult({required this.outcome, this.found});

  final ScanOutcome outcome;
  final OcrResult? found;
}
