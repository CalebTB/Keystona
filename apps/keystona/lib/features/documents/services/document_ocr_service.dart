import 'dart:io';

import '../models/document_ocr.dart';

/// Reads scanned pages and reports what it finds, stage by stage.
abstract interface class DocumentOcrService {
  /// Emits an [OcrProgress] each time a stage finishes and ends after the
  /// last stage. Errors on the stream mean the document could not be read.
  Stream<OcrProgress> read(List<File> pages);
}

/// The real reader: the `process-document-ocr` Edge Function.
///
/// [#1.7a] Not built yet. Until that Edge Function exists this throws, and the
/// reading card shows its error state.
class RemoteDocumentOcrService implements DocumentOcrService {
  const RemoteDocumentOcrService();

  @override
  Stream<OcrProgress> read(List<File> pages) => throw UnimplementedError(
    'process-document-ocr implemented by issue #1.7a',
  );
}
