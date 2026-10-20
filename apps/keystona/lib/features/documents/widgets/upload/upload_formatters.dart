import 'package:intl/intl.dart';

import '../../../../core/theme/aurora_docs_b.dart';
import '../../docs_copy.dart';

/// Pure text helpers for the new-document form.
abstract final class UploadFormatters {
  static const int _bytesPerKb = 1024;
  static const int _bytesPerMb = _bytesPerKb * _bytesPerKb;

  /// "PDF", "JPG", "PNG", "HEIC".
  static String typeLabel(String? mime) => switch (mime) {
    'application/pdf' => 'PDF',
    'image/png' => 'PNG',
    'image/heic' => 'HEIC',
    _ => 'JPG',
  };

  /// "1.4 MB", or "320 KB" under a megabyte.
  static String sizeLabel(int? bytes) {
    if (bytes == null) return '';
    if (bytes >= _bytesPerMb) {
      return '${(bytes / _bytesPerMb).toStringAsFixed(1)} MB';
    }
    final kb = (bytes / _bytesPerKb).ceil();
    return '$kb KB';
  }

  /// "PDF · 1.4 MB · JUST NOW".
  static String fileMeta(String? mime, int? bytes) => [
    typeLabel(mime),
    if (bytes != null) sizeLabel(bytes),
    'JUST NOW',
  ].join(' · ');

  /// "03/15/2031".
  static String fieldDate(DateTime date) =>
      DateFormat('MM/dd/yyyy').format(date);

  /// "REMIND YOU" help under the date: the reminder day, and where the date
  /// was found when smart scan read it.
  static String dateHelp(
    DateTime? date, {
    int? foundOnPage,
    bool renewing = false,
  }) {
    if (date == null) {
      return renewing ? DocsCopy.renewalDateHelp : 'Pick the date it ends';
    }
    final remind = DateTime(
      date.year,
      date.month,
      date.day - AuroraUploadRules.reminderLeadDays,
    );
    final base = 'Reminder on ${DateFormat.yMMMd().format(remind)}';
    return foundOnPage == null ? base : '$base · Found on page $foundOnPage';
  }

  /// "Smart scan read 4 details." for the banner (singular for one).
  static String scanHeadline(int count) =>
      'Smart scan read $count ${count == 1 ? 'detail' : 'details'}.';

  /// Category docs count: "9 DOCS", "1 DOC", "EMPTY".
  static String docCount(int count) => switch (count) {
    0 => 'EMPTY',
    1 => '1 DOC',
    _ => '$count DOCS',
  };
}
