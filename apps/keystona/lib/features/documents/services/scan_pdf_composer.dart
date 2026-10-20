import 'dart:convert';
import 'dart:typed_data';

/// One JPEG page to place in a PDF.
class ScanPdfPage {
  const ScanPdfPage({
    required this.jpegBytes,
    required this.width,
    required this.height,
  });

  final Uint8List jpegBytes;

  /// Pixel size of the image.
  final int width;
  final int height;
}

/// Builds a PDF with one full-page JPEG per page: several scanned pages become
/// the single file the vault stores.
///
/// Pure Dart, no dependencies. Only baseline RGB JPEGs are supported, which is
/// what the camera produces.
abstract final class ScanPdfComposer {
  /// Page width in PDF points (US Letter); height follows the image ratio.
  static const double pageWidthPoints = 612;

  static Uint8List compose(List<ScanPdfPage> pages) {
    assert(pages.isNotEmpty, 'A PDF needs at least one page');
    final out = BytesBuilder();
    final offsets = <int>[];

    void write(String text) => out.add(latin1.encode(text));

    // Object numbers: 1 catalog, 2 page tree, then page / content / image
    // per page starting at 3.
    int objectCount() => 2 + pages.length * 3;
    int pageObject(int i) => 3 + i * 3;

    write('%PDF-1.4\n');
    void begin(int number) {
      offsets.add(out.length);
      write('$number 0 obj\n');
    }

    begin(1);
    write('<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');

    begin(2);
    final kids = [
      for (var i = 0; i < pages.length; i++) '${pageObject(i)} 0 R',
    ];
    write(
      '<< /Type /Pages /Kids [${kids.join(' ')}] /Count ${pages.length} >>\n'
      'endobj\n',
    );

    for (var i = 0; i < pages.length; i++) {
      final page = pages[i];
      final w = pageWidthPoints;
      final h = pageWidthPoints * page.height / page.width;
      final pageNo = pageObject(i);

      begin(pageNo);
      write(
        '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 $w $h] '
        '/Resources << /XObject << /Im0 ${pageNo + 2} 0 R >> >> '
        '/Contents ${pageNo + 1} 0 R >>\nendobj\n',
      );

      final content = 'q $w 0 0 $h 0 0 cm /Im0 Do Q';
      begin(pageNo + 1);
      write(
        '<< /Length ${content.length} >>\nstream\n$content\nendstream\n'
        'endobj\n',
      );

      begin(pageNo + 2);
      write(
        '<< /Type /XObject /Subtype /Image /Width ${page.width} '
        '/Height ${page.height} /ColorSpace /DeviceRGB '
        '/BitsPerComponent 8 /Filter /DCTDecode '
        '/Length ${page.jpegBytes.length} >>\nstream\n',
      );
      out.add(page.jpegBytes);
      write('\nendstream\nendobj\n');
    }

    final xrefAt = out.length;
    write('xref\n0 ${objectCount() + 1}\n0000000000 65535 f \n');
    for (final offset in offsets) {
      write('${offset.toString().padLeft(10, '0')} 00000 n \n');
    }
    write(
      'trailer\n<< /Size ${objectCount() + 1} /Root 1 0 R >>\n'
      'startxref\n$xrefAt\n%%EOF\n',
    );
    return out.toBytes();
  }
}
