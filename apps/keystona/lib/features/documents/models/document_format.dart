import 'package:intl/intl.dart';

import 'document.dart';

/// Pure text formatting for document facts. Uppercase where the kit draws
/// mono labels.
abstract final class DocumentFormat {
  static const int _bytesPerKb = 1024;
  static const int _bytesPerMb = 1024 * 1024;

  /// Longest extension shown when the MIME type is unfamiliar.
  static const int _maxExtensionLength = 4;

  /// "PDF", "JPG", "PNG"... from a MIME type.
  static String extension(String? mime) {
    if (mime == null || mime.isEmpty) return 'FILE';
    if (mime.contains('pdf')) return 'PDF';
    if (mime.contains('jpeg') || mime.contains('jpg')) return 'JPG';
    if (mime.contains('png')) return 'PNG';
    if (mime.contains('heic')) return 'HEIC';
    if (mime.contains('gif')) return 'GIF';
    if (mime.contains('webp')) return 'WEBP';
    final ext = mime.split('/').last.toUpperCase();
    return ext.length > _maxExtensionLength
        ? ext.substring(0, _maxExtensionLength)
        : ext;
  }

  /// "1.4 MB", "820.0 KB", "512 B".
  static String fileSize(int bytes) {
    if (bytes < _bytesPerKb) return '$bytes B';
    if (bytes < _bytesPerMb) {
      return '${(bytes / _bytesPerKb).toStringAsFixed(1)} KB';
    }
    return '${(bytes / _bytesPerMb).toStringAsFixed(1)} MB';
  }

  /// "Mar 15, 2031".
  static String date(DateTime d) => DateFormat.yMMMd().format(d);

  /// "JAN 28" this year, "JAN 28, 2025" otherwise.
  static String shortDateUpper(DateTime d, {DateTime? now}) {
    final sameYear = d.year == (now ?? DateTime.now()).year;
    final f = sameYear ? DateFormat.MMMd() : DateFormat.yMMMd();
    return f.format(d).toUpperCase();
  }

  /// "MAR 2021".
  static String monthYearUpper(DateTime d) =>
      DateFormat.yMMM().format(d).toUpperCase();

  /// "PDF · 3 PAGES · 1.4 MB · ADDED TODAY".
  static String metaLine(Document doc, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final pages = doc.pageCount;
    final size = doc.fileSizeBytes;
    final added = DateTime(doc.createdAt.year, doc.createdAt.month, doc.createdAt.day);
    final isToday = added == DateTime(today.year, today.month, today.day);
    return [
      extension(doc.mimeType),
      if (pages != null) '$pages ${pages == 1 ? 'PAGE' : 'PAGES'}',
      if (size != null) fileSize(size).toUpperCase(),
      isToday
          ? 'ADDED TODAY'
          : 'ADDED ${shortDateUpper(doc.createdAt, now: today)}',
    ].join(' · ');
  }

  /// "net_worth" -> "Net worth"; keeps already readable keys intact.
  static String humanizeKey(String key) {
    final words = key.replaceAll('_', ' ').trim();
    if (words.isEmpty) return words;
    return '${words[0].toUpperCase()}${words.substring(1)}';
  }

  /// The file name part of a storage path.
  static String fileName(String path) => path.split('/').last;
}
