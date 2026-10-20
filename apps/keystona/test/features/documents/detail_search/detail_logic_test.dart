import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/documents/models/coverage_info.dart';
import 'package:keystona/features/documents/models/document_format.dart';
import 'package:keystona/features/documents/models/expiry_labels.dart';
import 'package:keystona/features/documents/models/expiring_groups.dart';
import 'package:keystona/features/documents/models/search_highlight.dart';
import 'package:keystona/features/documents/widgets/detail/document_facts_section.dart';
import 'package:keystona/features/documents/widgets/detail/document_file_section.dart';

import 'detail_search_support.dart';

void main() {
  final now = DateTime(2026, 10, 5, 15);

  group('ExpiryLabels', () {
    test('chip text follows the kit', () {
      expect(ExpiryLabels.chip(-3), 'EXPIRED');
      expect(ExpiryLabels.chip(0), 'TODAY');
      expect(ExpiryLabels.chip(1), '1 DAY');
      expect(ExpiryLabels.chip(8), '8 DAYS');
      expect(ExpiryLabels.chip(32), '32 DAYS');
      expect(ExpiryLabels.chip(65), '2 MONTHS');
      expect(ExpiryLabels.chip(268), '9 MONTHS');
      expect(ExpiryLabels.chip(400), '1 YEAR');
      expect(ExpiryLabels.chip(1100), '3 YEARS');
    });

    test('remaining text', () {
      expect(ExpiryLabels.remaining(45), '45 DAYS LEFT');
      expect(ExpiryLabels.remaining(1), '1 DAY LEFT');
      expect(ExpiryLabels.remaining(1620), '4 YRS 5 MOS LEFT');
      expect(ExpiryLabels.remaining(730), '2 YRS LEFT');
      expect(ExpiryLabels.remaining(-1), 'EXPIRED');
    });
  });

  group('CoverageInfo', () {
    test('is null without an end date', () {
      expect(CoverageInfo.of(fixtureDocument(), now: now), isNull);
    });

    test('uses the start date from the document and rounds the fraction', () {
      final doc = fixtureDocument(
        expiration: DateTime(2031, 3, 15),
        metadata: const {'start_date': '2021-03-15'},
      );
      final info = CoverageInfo.of(doc, now: DateTime(2023, 9, 15))!;
      expect(info.startedFromRecord, isTrue);
      expect(info.startLabel, 'STARTED MAR 2021');
      expect(info.title, 'Covered until Mar 15, 2031');
      expect(info.usedFraction, closeTo(0.25, 0.01));
    });

    test('falls back to the day it was added', () {
      final doc = fixtureDocument(expiration: DateTime(2031, 3, 15));
      final info = CoverageInfo.of(doc, now: now)!;
      expect(info.startedFromRecord, isFalse);
      expect(info.startLabel, startsWith('ADDED '));
    });

    test('an ended period reads Ended and is fully used', () {
      final doc = fixtureDocument(
        expiration: DateTime(2020, 1, 1),
        metadata: const {'start_date': '2015-01-01'},
      );
      final info = CoverageInfo.of(doc, now: now)!;
      expect(info.title, 'Ended Jan 1, 2020');
      expect(info.usedFraction, 1);
      expect(info.reminderDate(now: now), isNull);
    });

    test('the reminder is 30 days before the end', () {
      final doc = fixtureDocument(expiration: DateTime(2031, 3, 15));
      expect(
        CoverageInfo.of(doc, now: now)!.reminderDate(now: now),
        DateTime(2031, 2, 13),
      );
    });
  });

  group('DocumentFormat', () {
    test('file line matches the kit', () {
      final doc = fixtureDocument().copyWith(createdAt: now);
      expect(
        DocumentFormat.metaLine(doc, now: now),
        'PDF · 3 PAGES · 1.4 MB · ADDED TODAY',
      );
      expect(
        DocumentFormat.metaLine(
          doc.copyWith(createdAt: DateTime(2026, 10, 1), pageCount: 1),
          now: now,
        ),
        'PDF · 1 PAGE · 1.4 MB · ADDED OCT 1',
      );
    });

    test('dates add the year only when it is not this year', () {
      expect(DocumentFormat.shortDateUpper(DateTime(2026, 1, 28), now: now), 'JAN 28');
      expect(
        DocumentFormat.shortDateUpper(DateTime(2027, 1, 30), now: now),
        'JAN 30, 2027',
      );
    });

    test('fileName takes the last path segment', () {
      expect(DocumentFormat.fileName('u/p/northline-warranty.pdf'), 'northline-warranty.pdf');
    });
  });

  group('SearchHighlight', () {
    test('marks the first case-insensitive match', () {
      final spans = SearchHighlight.name('Dryer owner Manual', 'manual');
      expect(spans.map((s) => s.text), ['Dryer owner ', 'Manual']);
      expect(spans.map((s) => s.bold), [false, true]);
    });

    test('no query or no match leaves the name alone', () {
      expect(SearchHighlight.name('Deed', '').single.bold, isFalse);
      expect(SearchHighlight.name('Deed', 'zzz').single.text, 'Deed');
    });

    test('parses ** markers from the full-text snippet', () {
      final spans = SearchHighlight.snippet('Clean the **lint** trap');
      expect(spans.map((s) => s.text), ['Clean the ', 'lint', ' trap']);
      expect(spans.map((s) => s.bold), [false, true, false]);
    });
  });

  group('ExpiringGroups', () {
    final docs = [
      expiring('c', 'C', 117),
      expiring('a', 'A', 8),
      expiring('d', 'D', -10),
      expiring('b', 'B', 65),
      expiring('e', 'E', -500),
    ];

    test('orders bands and rows by urgency', () {
      final g = ExpiringGroups.of(docs, ExpiringRange.all);
      expect(g.upcoming.map((x) => x.band), [
        ExpiringBand.next30,
        ExpiringBand.next90,
        ExpiringBand.later,
      ]);
      expect(g.upcoming.expand((x) => x.documents).map((d) => d.id), [
        'a',
        'b',
        'c',
      ]);
    });

    test('ended documents are always listed, most recent first', () {
      for (final range in ExpiringRange.values) {
        expect(
          ExpiringGroups.of(docs, range).ended.map((d) => d.id),
          ['d', 'e'],
        );
      }
    });

    test('ranges cut off later bands', () {
      expect(
        ExpiringGroups.of(docs, ExpiringRange.days30).upcoming.map((x) => x.band),
        [ExpiringBand.next30],
      );
      expect(
        ExpiringGroups.of(docs, ExpiringRange.days90).upcoming.map((x) => x.band),
        [ExpiringBand.next30, ExpiringBand.next90],
      );
    });

    test('day 30 is urgent and day 31 is soon', () {
      final g = ExpiringGroups.of(
        [expiring('x', 'X', 30), expiring('y', 'Y', 31)],
        ExpiringRange.all,
      );
      expect(g.upcoming[0].documents.single.id, 'x');
      expect(g.upcoming[1].documents.single.id, 'y');
    });
  });

  group('detail sections', () {
    test('facts skip empty values and claim keys', () {
      final facts = DocumentFactsSection.factsOf(
        fixtureDocument(
          metadata: const {
            'parts': '10 years',
            'not_covered': 'Filters',
            'serial': '',
            'claim_phone': '1-800',
          },
        ),
      );
      expect(facts.map((f) => f.label), ['Parts', 'Not covered']);
    });

    test('claim line needs a phone number', () {
      expect(DocumentFactsSection.claimDetail(fixtureDocument()), isNull);
      expect(
        DocumentFactsSection.claimDetail(
          fixtureDocument(metadata: const {'claim_phone': '1-800-555-0142'}),
        ),
        '1-800-555-0142',
      );
    });

    test('storage label differs for free and Premium', () {
      expect(
        DocumentFileSection.storageLabel(count: 13, isPremium: false),
        'Encrypted · 13 of 25 used',
      );
      expect(
        DocumentFileSection.storageLabel(count: 13, isPremium: true),
        'Encrypted · 13 stored',
      );
      expect(
        DocumentFileSection.storageLabel(count: null, isPremium: false),
        'Encrypted',
      );
    });
  });
}
