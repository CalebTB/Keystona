import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/documents/docs_copy.dart';
import 'package:keystona/features/documents/models/category_lists.dart';
import 'package:keystona/features/documents/models/docs_expiry.dart';
import 'package:keystona/features/documents/models/docs_tab_data.dart';
import 'package:keystona/features/documents/models/document.dart';
import 'package:keystona/features/documents/widgets/document_card.dart';
import 'package:keystona/features/documents/widgets/expiration_badge.dart';

import '../../../support/responsive_harness.dart';
import 'docs_tab_test_support.dart';

final DateTime _today = DateTime(2026, 10, 4, 15);

DocsExpiry _in(int days) =>
    DocsExpiry.of(DateTime(2026, 10, 4 + days), now: _today);

void main() {
  group('DocsExpiry', () {
    test('counts calendar days, not 24 hour blocks', () {
      expect(_in(0).days, 0);
      expect(_in(9).days, 9);
      expect(_in(-1).days, -1);
      // Late in the day, a date later today is still today.
      expect(
        DocsExpiry.of(
          DateTime(2026, 10, 4, 1),
          now: DateTime(2026, 10, 4, 23),
        ).days,
        0,
      );
    });

    test('tones: urgent to 30 days, soon to 90, then far', () {
      expect(_in(-5).tone, DocsExpiryTone.urgent);
      expect(_in(30).tone, DocsExpiryTone.urgent);
      expect(_in(31).tone, DocsExpiryTone.soon);
      expect(_in(90).tone, DocsExpiryTone.soon);
      expect(_in(91).tone, DocsExpiryTone.far);
      expect(_in(91).isSoon, isFalse);
    });

    test('pill words always accompany the color', () {
      expect(DocsCopy.rowPill(_in(9)), '9 DAYS');
      expect(DocsCopy.rowPill(_in(1)), '1 DAY');
      expect(DocsCopy.rowPill(_in(0)), 'TODAY');
      expect(DocsCopy.rowPill(_in(-3)), 'EXPIRED');
      expect(DocsCopy.rowPill(_in(2000)), 'TO 2032');
      expect(DocsCopy.rowPill(_in(45), long: true), 'EXPIRES IN 45 DAYS');
      expect(DocsCopy.daysLeft(_in(9)), '9 DAYS left');
      expect(DocsCopy.daysLeft(_in(-3)), 'Expired');
    });
  });

  group('DocsTabData', () {
    final data = DocsTabData(
      totalCount: 4,
      expiring: [
        item('a', 'Expired', expiresInDays: -2),
        item('b', 'Urgent', expiresInDays: 10),
        item('c', 'Soon', expiresInDays: 60),
        item('d', 'Far', expiresInDays: 500),
      ],
    );

    test('soon includes expired, urgent and the 90 day window', () {
      expect(data.soon().map((d) => d.id), ['a', 'b', 'c']);
    });

    test('urgent is 30 days or fewer, expired included', () {
      expect(data.urgent().map((d) => d.id), ['a', 'b']);
    });

    test('empty only when the vault has no documents', () {
      expect(const DocsTabData().isEmpty, isTrue);
      expect(data.isEmpty, isFalse);
    });
  });

  group('DocsCopy', () {
    test('plan eyebrow follows the plan', () {
      expect(DocsCopy.eyebrow(12, isPremium: false), startsWith('12 OF '));
      expect(DocsCopy.eyebrow(12, isPremium: true), '12 DOCUMENTS · PREMIUM');
      expect(DocsCopy.eyebrow(1, isPremium: true), '1 DOCUMENT · PREMIUM');
    });

    test('row meta is category and date, upper case', () {
      expect(
        DocsCopy.rowMeta('Maintenance', DateTime(2026, 10, 2)),
        'MAINTENANCE · OCT 2',
      );
      expect(DocsCopy.rowMeta(null, DateTime(2026, 10, 2)), 'OCT 2');
      expect(
        DocsCopy.addedMeta('Insurance', DateTime(2026, 5, 12)),
        'INSURANCE · ADDED MAY 12',
      );
    });

    test('insurance keeps the kit sentence, others get a plain one', () {
      final date = DateTime(2026, 10, 13);
      expect(
        DocsCopy.expiringBody(categoryName: 'Insurance', date: date),
        'Renews Oct 13. Upload the new declarations page so your coverage '
        'stays on record.',
      );
      expect(
        DocsCopy.expiringBody(categoryName: 'Warranties', date: date),
        'Expires Oct 13. Upload the new copy so it stays on record.',
      );
    });

    test('empty-category hint exists for Tax & financial only', () {
      expect(DocsCopy.nothingIn('Tax & financial'), 'Nothing in Financial yet');
      expect(
        DocsCopy.hintFor('Tax & financial'),
        'Mortgage papers, tax bills, improvement receipts',
      );
      expect(DocsCopy.hintFor('Warranty'), isNull);
    });
  });

  group('CategoryLists', () {
    final all = [
      ...standardCategories(),
      category('c1', 'A', sortOrder: 21),
      category('c2', 'B', sortOrder: 22),
      category('c3', 'C', sortOrder: 25),
    ];
    final lists = CategoryLists(all);

    test('splits standard from custom, in sort order', () {
      expect(lists.standard.map((c) => c.id), ['s1', 's2', 's3', 's9']);
      expect(lists.custom.map((c) => c.id), ['c1', 'c2', 'c3']);
      expect(lists.nextSortOrder, 26);
    });

    test('move targets are Other, Manual, Receipt in kit order', () {
      expect(lists.moveTargets.map((c) => c.name), [
        'Other',
        'Manual',
        'Receipt',
      ]);
      expect(lists.defaultMoveTarget!.id, 's9');
    });

    test('falls back to the first standard categories when names differ', () {
      final odd = CategoryLists([
        category('x1', 'Alpha', system: true, sortOrder: 1),
        category('x2', 'Beta', system: true, sortOrder: 2),
      ]);
      expect(odd.moveTargets.map((c) => c.id), ['x1', 'x2']);
      expect(CategoryLists(const []).defaultMoveTarget, isNull);
    });

    test('reorder reuses the existing slots and honors Flutter indices', () {
      // Drag A to the end: Flutter reports newIndex 3 for "after C".
      expect(lists.reorder(0, 3), {'c2': 21, 'c3': 22, 'c1': 25});
      // Drag C to the front.
      expect(lists.reorder(2, 0), {'c3': 21, 'c1': 22, 'c2': 25});
      // Drag A one place down: newIndex 2 means "before C".
      expect(lists.reorder(0, 2), {'c2': 21, 'c1': 22, 'c3': 25});
    });

    test('the limit is ten', () {
      final ten = CategoryLists([
        for (var i = 0; i < 10; i++) category('c$i', 'C$i', sortOrder: i),
      ]);
      expect(ten.canAddMore, isFalse);
      expect(lists.canAddMore, isTrue);
    });
  });

  group('ExpirationBadge and DocumentCard', () {
    Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

    testWidgets('badge words match the urgency', (tester) async {
      Future<void> pump(int days, {bool large = false}) => tester.pumpWidget(
        host(ExpirationBadge(expirationDate: inDays(days), large: large)),
      );
      await pump(9);
      expect(find.text('9 DAYS'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
      await pump(-4);
      expect(find.text('EXPIRED'), findsOneWidget);
      await pump(45, large: true);
      expect(find.text('EXPIRES IN 45 DAYS'), findsOneWidget);
      await pump(1000);
      expect(find.text('TO ${inDays(1000).year}'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsNothing);
    });

    testWidgets('card shows the row and opens the detail route', (
      tester,
    ) async {
      final visited = <String>[];
      final doc = Document(
        id: 'd1',
        propertyId: 'p',
        userId: 'u',
        name: 'Roof warranty',
        categoryId: 'c',
        filePath: 'f.pdf',
        createdAt: DateTime(2026, 9, 14),
        updatedAt: DateTime(2026, 9, 14),
        category: category('c', 'Warranties', system: true),
      );
      await tester.pumpWidget(
        RoutedApp(
          home: Scaffold(body: DocumentCard(document: doc)),
          visited: visited,
        ),
      );
      expect(find.text('Roof warranty'), findsOneWidget);
      expect(find.text('WARRANTIES · SEP 14'), findsOneWidget);
      await tester.tap(find.text('Roof warranty'));
      await tester.pump(const Duration(seconds: 1));
      expect(visited, ['/documents/d1']);
    });

    testResponsive(
      'DocumentCard with a long name',
      () => Scaffold(
        body: DocumentCard(
          document: Document(
            id: 'd1',
            propertyId: 'p',
            userId: 'u',
            name: 'A very long document name that keeps going and going',
            categoryId: 'c',
            filePath: 'f.pdf',
            createdAt: DateTime(2026, 9, 14),
            updatedAt: DateTime(2026, 9, 14),
            expirationDate: inDays(9),
            category: category('c', 'Inspection report', system: true),
          ),
        ),
      ),
    );
  });
}
