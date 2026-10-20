import 'document.dart';
import 'document_format.dart';
import 'docs_expiry.dart';
import 'expiry_labels.dart';

/// How much of a document's coverage period has passed: warranty, policy,
/// permit, anything with an end date.
class CoverageInfo {
  const CoverageInfo({
    required this.expiry,
    required this.endDate,
    required this.startDate,
    required this.startedFromRecord,
    required this.usedFraction,
  });

  final DocsExpiry expiry;
  final DateTime endDate;
  final DateTime startDate;

  /// True when [startDate] comes from the document's own details; false when
  /// it falls back to the day the document was added.
  final bool startedFromRecord;

  /// 0..1 of the period already used.
  final double usedFraction;

  /// Metadata keys that may hold the start of coverage, in order.
  static const List<String> startKeys = [
    'start_date',
    'effective_date',
    'purchase_date',
    'install_date',
    'issued_date',
  ];

  /// The coverage view of [doc], or null when it has no end date.
  static CoverageInfo? of(Document doc, {DateTime? now}) {
    final end = doc.expirationDate;
    if (end == null) return null;
    final today = now ?? DateTime.now();

    DateTime? fromRecord;
    for (final key in startKeys) {
      final raw = doc.metadata[key];
      if (raw is String) {
        fromRecord = DateTime.tryParse(raw);
        if (fromRecord != null) break;
      }
    }
    final start = fromRecord ?? doc.createdAt;
    final total = end.difference(start).inMilliseconds;
    final used = today.difference(start).inMilliseconds;
    final fraction = total <= 0 ? 1.0 : (used / total).clamp(0.0, 1.0);

    return CoverageInfo(
      expiry: DocsExpiry.of(end, now: today),
      endDate: end,
      startDate: start,
      startedFromRecord: fromRecord != null,
      usedFraction: fraction,
    );
  }

  /// "Covered until Mar 15, 2031" or "Ended Mar 15, 2031".
  String get title => expiry.expired
      ? 'Ended ${DocumentFormat.date(endDate)}'
      : 'Covered until ${DocumentFormat.date(endDate)}';

  /// "STARTED MAR 2021" or "ADDED MAR 2021".
  String get startLabel =>
      '${startedFromRecord ? 'STARTED' : 'ADDED'} '
      '${DocumentFormat.monthYearUpper(startDate)}';

  /// The day the reminder fires, or null when it has already passed.
  DateTime? reminderDate({DateTime? now}) {
    final today = now ?? DateTime.now();
    final day = DateTime(
      endDate.year,
      endDate.month,
      endDate.day - ExpiryLabels.reminderLeadDays,
    );
    final todayOnly = DateTime(today.year, today.month, today.day);
    return day.isBefore(todayOnly) ? null : day;
  }
}
