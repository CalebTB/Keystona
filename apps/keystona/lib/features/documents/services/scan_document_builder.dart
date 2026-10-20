import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';

import '../models/document_scan.dart';
import 'scan_pdf_composer.dart';

/// Turns the pages the camera captured into the one file the vault stores.
///
/// One page stays the photo it is; several pages become a single PDF.
class ScanDocumentBuilder {
  const ScanDocumentBuilder();

  Future<ScanOutcome> build(List<File> pages, {required bool smart}) async {
    assert(pages.isNotEmpty, 'Nothing was captured');
    if (pages.length == 1) {
      return ScanOutcome(
        file: pages.first,
        mimeType: 'image/jpeg',
        sizeBytes: await pages.first.length(),
        pageCount: 1,
        previewFile: pages.first,
        smart: smart,
      );
    }

    final composed = <ScanPdfPage>[];
    for (final page in pages) {
      final bytes = await page.readAsBytes();
      final image = await _decode(bytes);
      composed.add(
        ScanPdfPage(jpegBytes: bytes, width: image.width, height: image.height),
      );
      image.dispose();
    }

    final dir = await getTemporaryDirectory();
    final target = File(
      '${dir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    final pdf = ScanPdfComposer.compose(composed);
    await target.writeAsBytes(pdf, flush: true);
    return ScanOutcome(
      file: target,
      mimeType: 'application/pdf',
      sizeBytes: pdf.length,
      pageCount: pages.length,
      previewFile: pages.first,
      smart: smart,
    );
  }

  Future<ui.Image> _decode(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }
}
