import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keystona/core/router/app_router.dart';
import 'package:keystona/core/widgets/aurora/aurora_button.dart';
import 'package:keystona/core/widgets/aurora/aurora_chip.dart';
import 'package:keystona/features/documents/docs_copy.dart';
import 'package:keystona/features/documents/models/docs_tab_data.dart';
import 'package:keystona/features/documents/models/document_format.dart';
import 'package:keystona/features/documents/models/document_renewal.dart';
import 'package:keystona/features/documents/models/expiring_document.dart';
import 'package:keystona/features/documents/models/expiring_groups.dart';
import 'package:keystona/features/documents/providers/document_repositories_provider.dart';
import 'package:keystona/features/documents/screens/documents_expiring_screen.dart';
import 'package:keystona/features/documents/screens/documents_screen.dart';
import 'package:keystona/features/documents/widgets/expiration_badge.dart';
import 'package:keystona/features/documents/widgets/expiring/expiring_ended_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../detail_search/detail_search_support.dart' as detail;
import '../tab/docs_tab_test_support.dart';

final DateTime _replacedOn = DateTime(2025, 10, 4);

DocsTabItem _replaced(String id, String name, {int expiresInDays = 9}) =>
    DocsTabItem(
      id: id,
      name: name,
      createdAt: DateTime.now().subtract(const Duration(days: 100)),
      categoryName: 'Insurance',
      expirationDate: inDays(expiresInDays),
      replacedAt: _replacedOn,
    );

ExpiringDocument _exp(
  String id,
  String name,
  int days, {
  DateTime? replacedAt,
}) => ExpiringDocument(
  id: id,
  name: name,
  categoryName: 'Insurance',
  categoryIcon: 'shield',
  expirationDate: detail.daysFromNow(days),
  replacedAt: replacedAt,
);

/// Routes the screen under test at `/` and records every upload location.
class _Harness extends StatelessWidget {
  _Harness({
    required Widget home,
    required List<Override> overrides,
    required this.visited,
  }) : _overrides = overrides,
       _router = GoRouter(
         routes: [
           GoRoute(path: '/', builder: (_, _) => home),
           GoRoute(
             path: AppRoutes.documentsUpload,
             builder: (_, state) {
               visited.add(state.uri.toString());
               return const Scaffold(body: Text('upload route'));
             },
           ),
           GoRoute(
             path: AppRoutes.documentsExpiring,
             builder: (_, _) => const Scaffold(body: Text('expiring route')),
           ),
         ],
       );

  final List<String> visited;
  final List<Override> _overrides;
  final GoRouter _router;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: _overrides,
    retry: (_, _) => null,
    child: MaterialApp.router(routerConfig: _router),
  );
}

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('route', () {
    test('location carries the id in the renew query parameter', () {
      final uri = Uri.parse(
        DocumentRenewal.location(AppRoutes.documentsUpload, 'old 1'),
      );
      expect(uri.path, AppRoutes.documentsUpload);
      expect(uri.queryParameters, {DocumentRenewal.queryParam: 'old 1'});
    });

    test('replaced metadata merges in and keeps every other key', () {
      final merged = DocumentRenewal.withReplaced(
        {'tags': ['a'], 'provider': 'Statewide Mutual'},
        on: DateTime(2026, 10, 6, 15, 30),
        by: 'new-1',
      );
      expect(merged, {
        'tags': ['a'],
        'provider': 'Statewide Mutual',
        'replaced_at': '2026-10-06',
        'replaced_by': 'new-1',
      });
      expect(DocumentRenewal.replacedAt(merged), DateTime(2026, 10, 6));
      expect(DocumentRenewal.replacedBy(merged), 'new-1');
      expect(DocumentRenewal.replacedAt(const {}), isNull);
      expect(DocumentRenewal.replacedAt(null), isNull);
      expect(DocumentRenewal.withReplaced(null, on: _replacedOn, by: 'x'), {
        'replaced_at': '2025-10-04',
        'replaced_by': 'x',
      });
    });
  });

  group('Docs tab', () {
    final data = DocsTabData(
      totalCount: 12,
      recent: [item('x', 'Fresh receipt'), _replaced('old', 'Old policy')],
      expiring: [
        _replaced('old', 'Old policy'),
        item('dish', 'Bosch dishwasher warranty', expiresInDays: 45),
      ],
    );

    test('replaced documents drop out of active, soon and urgent', () {
      expect(data.active.map((d) => d.id), ['dish']);
      expect(data.soon().map((d) => d.id), ['dish']);
      expect(data.urgent(), isEmpty);
      expect(data.expiring, hasLength(2));
    });

    testWidgets('no urgent card, no urgency count, no badge on the old one', (
      tester,
    ) async {
      _tall(tester);
      final visited = <String>[];
      await tester.pumpWidget(
        _Harness(
          home: const DocumentsScreen(),
          overrides: tabOverrides(FakeDocsTabRepository(data)),
          visited: visited,
        ),
      );
      await _settle(tester);

      expect(find.text('EXPIRING SOON'), findsNothing);
      expect(find.text(DocsCopy.uploadRenewal), findsNothing);
      expect(find.textContaining('expiring soon'), findsNothing);
      expect(find.text('All expiring dates · 1'), findsOneWidget);
      // Recently added still lists it, with no urgency pill.
      expect(find.text('Old policy'), findsOneWidget);
      expect(find.byType(ExpirationBadge), findsNothing);
    });

    testWidgets('the hero is the next document that is still in force', (
      tester,
    ) async {
      _tall(tester);
      final urgent = item('ins', 'Auto policy', expiresInDays: 12);
      final withBoth = DocsTabData(
        totalCount: 3,
        recent: [urgent],
        expiring: [_replaced('old', 'Old policy', expiresInDays: 2), urgent],
      );
      await tester.pumpWidget(
        _Harness(
          home: const DocumentsScreen(),
          overrides: tabOverrides(FakeDocsTabRepository(withBoth)),
          visited: [],
        ),
      );
      await _settle(tester);
      expect(find.text('1 expiring soon'), findsOneWidget);
      expect(find.text('12 DAYS LEFT'), findsOneWidget);
      expect(find.textContaining('more ·'), findsNothing);
      expect(find.text('All expiring dates · 1'), findsOneWidget);
    });

    testWidgets('Upload renewal opens the add flow for that document', (
      tester,
    ) async {
      _tall(tester);
      final visited = <String>[];
      await tester.pumpWidget(
        _Harness(
          home: const DocumentsScreen(),
          overrides: tabOverrides(FakeDocsTabRepository(populatedData())),
          visited: visited,
        ),
      );
      await _settle(tester);
      await tester.tap(find.text(DocsCopy.uploadRenewal));
      await _settle(tester);
      expect(visited, ['/documents/upload?renew=ins']);
    });

    testWidgets('the plus button still opens a blank add flow', (tester) async {
      _tall(tester);
      final visited = <String>[];
      await tester.pumpWidget(
        _Harness(
          home: const DocumentsScreen(),
          overrides: tabOverrides(FakeDocsTabRepository(populatedData())),
          visited: visited,
        ),
      );
      await _settle(tester);
      await tester.tap(find.bySemanticsLabel('Add a document'));
      await _settle(tester);
      expect(visited, ['/documents/upload']);
    });
  });

  group('Expiring', () {
    final list = [
      _exp('ins', 'Homeowners insurance policy', 8),
      _exp('wash', 'Halden washer warranty', 65),
      _exp('replaced-future', 'Renewed umbrella policy', 20, replacedAt: _replacedOn),
      _exp('old1', 'Calder water heater warranty', -400),
      _exp(
        'replaced-past',
        'Previous homeowners policy',
        -300,
        replacedAt: _replacedOn,
      ),
    ];

    test('replaced documents are never upcoming, only ended', () {
      final groups = ExpiringGroups.of(list, ExpiringRange.all);
      final upcoming = [
        for (final g in groups.upcoming) ...g.documents.map((d) => d.id),
      ];
      expect(upcoming, ['ins', 'wash']);
      expect(groups.ended.map((d) => d.id).toSet(), {
        'replaced-future',
        'old1',
        'replaced-past',
      });
    });

    testWidgets('groups and counts leave replaced documents out', (
      tester,
    ) async {
      _tall(tester);
      await tester.pumpWidget(
        _Harness(
          home: const DocumentsExpiringScreen(),
          overrides: [
            expiringDocumentsRepositoryProvider.overrideWithValue(
              detail.FakeExpiringRepository(list),
            ),
          ],
          visited: [],
        ),
      );
      await _settle(tester);

      expect(find.text('NEXT 30 DAYS'), findsOneWidget);
      expect(find.text('1 ITEM'), findsWidgets);
      expect(find.text('Renewed umbrella policy'), findsOneWidget);
      // The replaced one sits only in "Already ended", never as a card.
      expect(find.text('ALREADY ENDED · 3'), findsOneWidget);
      expect(find.text(DocsCopy.uploadRenewal), findsOneWidget);

      final replacedMeta = DocsCopy.endedMeta(
        endedOn: detail.daysFromNow(-300),
        replacedAt: _replacedOn,
      );
      expect(
        replacedMeta,
        'REPLACED ${DocumentFormat.monthYearUpper(_replacedOn)} · '
        'KEPT FOR CLAIMS HISTORY',
      );
      expect(find.text(replacedMeta), findsNWidgets(2));
      expect(
        find.text(
          'ENDED ${DocumentFormat.monthYearUpper(detail.daysFromNow(-400))}'
          ' · KEPT FOR YOUR RECORD',
        ),
        findsOneWidget,
      );
    });

    testWidgets('ended rows: name over meta on the left, chevron far right', (
      tester,
    ) async {
      _tall(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpiringEndedSection(
              documents: [list.last],
              onOpen: (_) {},
            ),
          ),
        ),
      );
      final width = tester.view.physicalSize.width;
      final name = tester.getRect(find.text('Previous homeowners policy'));
      final meta = tester.getRect(
        find.textContaining('REPLACED').first,
      );
      final chevron = tester.getRect(find.byType(Icon));
      expect(meta.top, greaterThan(name.bottom - 1));
      expect(meta.left, closeTo(name.left, 0.5));
      expect(chevron.left, greaterThan(name.right));
      expect(width - chevron.right, lessThan(width * 0.1));
    });

    testWidgets('card: chip and date are right-aligned, name left', (
      tester,
    ) async {
      _tall(tester);
      await tester.pumpWidget(
        _Harness(
          home: const DocumentsExpiringScreen(),
          overrides: [
            expiringDocumentsRepositoryProvider.overrideWithValue(
              detail.FakeExpiringRepository([list.first]),
            ),
          ],
          visited: [],
        ),
      );
      await _settle(tester);
      final width = tester.view.physicalSize.width;
      final name = tester.getRect(find.text('Homeowners insurance policy'));
      final chip = tester.getRect(find.byType(StatusChip));
      final button = tester.getRect(find.byType(PrimaryButton));
      expect(chip.left, greaterThan(name.right));
      expect(chip.right, greaterThan(width * 0.8));
      expect(chip.right, lessThanOrEqualTo(button.right + 0.5));
      expect(button.top, greaterThan(chip.bottom));
      expect(button.left, lessThan(name.left));
    });

    testWidgets('Upload renewal passes the card\'s document id', (
      tester,
    ) async {
      _tall(tester);
      final visited = <String>[];
      await tester.pumpWidget(
        _Harness(
          home: const DocumentsExpiringScreen(),
          overrides: [
            expiringDocumentsRepositoryProvider.overrideWithValue(
              detail.FakeExpiringRepository(list),
            ),
          ],
          visited: visited,
        ),
      );
      await _settle(tester);
      await tester.tap(find.text(DocsCopy.uploadRenewal));
      await _settle(tester);
      expect(visited, ['/documents/upload?renew=ins']);
    });
  });
}
