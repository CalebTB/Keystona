import 'expiring_document.dart';
import 'docs_expiry.dart';

/// How far ahead the Expiring screen looks.
enum ExpiringRange {
  days30('30 days', DocsExpiry.urgentDays),
  days90('90 days', DocsExpiry.soonDays),
  all('All', null);

  const ExpiringRange(this.label, this.withinDays);

  final String label;

  /// Documents ending later than this are hidden. Null shows everything.
  final int? withinDays;
}

/// The urgency bands the screen groups documents into.
enum ExpiringBand {
  next30('Next 30 days'),
  next90('Next 90 days'),
  later('Later');

  const ExpiringBand(this.title);

  final String title;

  static ExpiringBand of(DocsExpiry info) {
    if (info.days <= DocsExpiry.urgentDays) return ExpiringBand.next30;
    if (info.days <= DocsExpiry.soonDays) return ExpiringBand.next90;
    return ExpiringBand.later;
  }
}

/// Documents of one band, soonest first.
class ExpiringGroup {
  const ExpiringGroup(this.band, this.documents);

  final ExpiringBand band;
  final List<ExpiringDocument> documents;
}

/// Pure grouping for the Expiring screen: by urgency, soonest first, with
/// documents whose end date has passed, or that were replaced by a newer
/// copy, set apart.
class ExpiringGroups {
  const ExpiringGroups({required this.upcoming, required this.ended});

  /// Non-empty bands in [range], soonest band first.
  final List<ExpiringGroup> upcoming;

  /// Documents already past their end date or replaced, most recent first.
  final List<ExpiringDocument> ended;

  factory ExpiringGroups.of(
    List<ExpiringDocument> documents,
    ExpiringRange range, {
    DateTime? now,
  }) {
    final dated = [
      for (final d in documents) (doc: d, info: DocsExpiry.of(d.expirationDate, now: now)),
    ]..sort((a, b) => a.info.days.compareTo(b.info.days));

    final limit = range.withinDays;
    final upcoming = <ExpiringBand, List<ExpiringDocument>>{};
    final ended = <ExpiringDocument>[];
    for (final item in dated) {
      if (item.doc.isReplaced || item.info.expired) {
        ended.add(item.doc);
      } else if (limit == null || item.info.days <= limit) {
        upcoming.putIfAbsent(ExpiringBand.of(item.info), () => []).add(item.doc);
      }
    }

    return ExpiringGroups(
      upcoming: [
        for (final band in ExpiringBand.values)
          if (upcoming[band] != null) ExpiringGroup(band, upcoming[band]!),
      ],
      ended: ended.reversed.toList(),
    );
  }

  bool get hasUpcoming => upcoming.isNotEmpty;
}
