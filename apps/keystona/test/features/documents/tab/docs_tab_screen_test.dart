import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keystona/features/documents/docs_copy.dart';
import 'package:keystona/features/documents/models/docs_tab_data.dart';
import 'package:keystona/features/documents/screens/documents_screen.dart';
import 'package:keystona/features/documents/widgets/docs_tab/docs_empty_view.dart';
import 'package:keystona/features/documents/widgets/docs_tab/docs_tab_skeleton.dart';
import 'package:keystona/features/subscription/providers/subscription_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'docs_tab_test_support.dart';

Widget _app(
  FakeDocsTabRepository repository, {
  bool premium = false,
  List<String>? visited,
}) => RoutedApp(
  home: const DocumentsScreen(),
  overrides: tabOverrides(repository, premium: premium),
  visited: visited,
);

/// A tall surface so the whole tab is on screen without scrolling.
void _tallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await _settle(tester);
}

/// Lets routes and async loads finish. The pulse and shimmer animations
/// repeat forever, so `pumpAndSettle` would never return.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Docs tab states', () {
    testWidgets('shows the skeleton on the first frame', (tester) async {
      final gate = Completer<void>();
      final repo = FakeDocsTabRepository(populatedData(), gate: gate);
      await tester.pumpWidget(_app(repo));
      await tester.pump();
      expect(find.byType(DocsTabSkeleton), findsOneWidget);
      expect(find.text('Documents'), findsNothing);
      gate.complete();
      await tester.pump();
      await tester.pump();
      expect(find.byType(DocsTabSkeleton), findsNothing);
      expect(find.text('Documents'), findsOneWidget);
    });

    testWidgets('populated: header, search, expiring card and recent list', (
      tester,
    ) async {
      _tallSurface(tester);
      await tester.pumpWidget(_app(FakeDocsTabRepository(populatedData())));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('12 OF $kFreeDocumentLimit · FREE PLAN'),
        findsOneWidget,
      );
      expect(find.text('1 expiring soon'), findsOneWidget);
      expect(find.text('Search or pick a category'), findsOneWidget);
      expect(find.text('EXPIRING SOON'), findsOneWidget);
      expect(find.text('9 DAYS LEFT'), findsOneWidget);
      expect(find.text('Upload renewal'), findsOneWidget);
      expect(find.text('Remind me'), findsOneWidget);
      expect(
        find.textContaining('1 more · Bosch dishwasher warranty ends'),
        findsOneWidget,
      );
      expect(find.text('All expiring dates · 3'), findsOneWidget);
      expect(find.text('RECENTLY ADDED'), findsOneWidget);
      expect(find.text('See all 12'), findsOneWidget);
      expect(find.text('Dryer vent service receipt'), findsOneWidget);
      expect(find.text('TO ${inDays(3000).year}'), findsOneWidget);
      expect(find.text('45 DAYS'), findsOneWidget);
      expect(find.text('9 DAYS'), findsOneWidget);
      expect(find.text('Nothing in Financial yet'), findsOneWidget);
    });

    testWidgets('premium plan swaps the plan label', (tester) async {
      await tester.pumpWidget(
        _app(FakeDocsTabRepository(populatedData()), premium: true),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('12 DOCUMENTS · PREMIUM'), findsOneWidget);
    });

    testWidgets('nothing urgent: no coral card, link to all dates stays', (
      tester,
    ) async {
      final far = item('far', 'Roof', expiresInDays: 400);
      final repo = FakeDocsTabRepository(
        DocsTabData(totalCount: 1, recent: [far], expiring: [far]),
      );
      await tester.pumpWidget(_app(repo));
      await tester.pump();
      await tester.pump();
      expect(find.text('EXPIRING SOON'), findsNothing);
      expect(find.text('Upload renewal'), findsNothing);
      expect(find.text('All expiring dates · 1'), findsOneWidget);
    });

    testWidgets('empty vault: one clear action and three suggestions', (
      tester,
    ) async {
      await tester.pumpWidget(_app(FakeDocsTabRepository(const DocsTabData())));
      await tester.pump();
      await tester.pump();
      expect(find.byType(DocsEmptyView), findsOneWidget);
      expect(find.text('0 OF $kFreeDocumentLimit · FREE PLAN'), findsOneWidget);
      expect(find.text('Your vault is ready'), findsOneWidget);
      expect(find.text('Add a document'), findsOneWidget);
      expect(find.text('Scan with camera'), findsOneWidget);
      expect(find.text('START WITH THESE'), findsOneWidget);
      expect(find.text('Homeowners insurance policy'), findsOneWidget);
      expect(find.text('Closing disclosure'), findsOneWidget);
      expect(find.text('An appliance warranty'), findsOneWidget);
      expect(find.text(DocsCopy.emptyFootnote), findsOneWidget);
    });

    testWidgets('error shows retry, and retry reloads', (tester) async {
      final repo = FakeDocsTabRepository(populatedData())
        ..failWith = StateError('offline');
      await tester.pumpWidget(_app(repo));
      await tester.pump();
      await tester.pump();
      expect(find.text(DocsCopy.loadError), findsOneWidget);

      repo.failWith = null;
      await _tap(tester, find.text('Try again'));
      expect(find.text(DocsCopy.loadError), findsNothing);
      expect(find.text('RECENTLY ADDED'), findsOneWidget);
      expect(repo.loads, 2);
    });

    testWidgets('pull to refresh reloads the data', (tester) async {
      final repo = FakeDocsTabRepository(populatedData());
      await tester.pumpWidget(_app(repo));
      await tester.pump();
      await tester.pump();
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 400),
        1000,
      );
      await _settle(tester);
      await _settle(tester);
      expect(repo.loads, 2);
    });
  });

  group('Docs tab navigation', () {
    Future<void> load(
      WidgetTester tester,
      FakeDocsTabRepository repo, {
      List<String>? visited,
      bool premium = false,
    }) async {
      _tallSurface(tester);
      await tester.pumpWidget(_app(repo, visited: visited, premium: premium));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('search field opens search', (tester) async {
      final visited = <String>[];
      await load(
        tester,
        FakeDocsTabRepository(populatedData()),
        visited: visited,
      );
      await _tap(tester, find.text('Search or pick a category'));
      expect(visited, ['/documents/search']);
    });

    testWidgets('plus and Upload renewal open the add flow', (tester) async {
      final visited = <String>[];
      await load(
        tester,
        FakeDocsTabRepository(populatedData()),
        visited: visited,
      );
      await _tap(tester, find.bySemanticsLabel('Add a document'));
      expect(visited, ['/documents/upload']);
    });

    testWidgets('a recent row opens the document', (tester) async {
      final visited = <String>[];
      await load(
        tester,
        FakeDocsTabRepository(populatedData()),
        visited: visited,
      );
      await _tap(tester, find.text('Dryer vent service receipt'));
      expect(visited, ['/documents/dryer']);
    });

    testWidgets('the next expiring line opens that document', (tester) async {
      final visited = <String>[];
      await load(
        tester,
        FakeDocsTabRepository(populatedData()),
        visited: visited,
      );
      await _tap(tester, find.textContaining('1 more ·'));
      expect(visited, ['/documents/dish']);
    });

    testWidgets('All expiring dates opens the expiring list', (tester) async {
      final visited = <String>[];
      await load(
        tester,
        FakeDocsTabRepository(populatedData()),
        visited: visited,
      );
      await _tap(tester, find.text('All expiring dates · 3'));
      expect(visited, ['/documents/expiring']);
    });

    testWidgets('Remind me says reminders are not available yet', (
      tester,
    ) async {
      final repo = FakeDocsTabRepository(populatedData());
      await load(tester, repo);
      await _tap(tester, find.text('Remind me'));
      expect(repo.reminders, ['ins']);
      expect(find.text(DocsCopy.remindUnavailable), findsOneWidget);
    });

    testWidgets('returning from a pushed screen reloads the tab', (
      tester,
    ) async {
      final repo = FakeDocsTabRepository(populatedData());
      await load(tester, repo);
      await _tap(tester, find.text('Dryer vent service receipt'));
      GoRouter.of(
        tester.element(find.textContaining('route /documents/dryer')),
      ).pop();
      await _settle(tester);
      expect(repo.loads, 2);
    });

    testWidgets('free plan at the limit shows the upgrade sheet, not upload', (
      tester,
    ) async {
      final visited = <String>[];
      final data = populatedData();
      final full = DocsTabData(
        totalCount: kFreeDocumentLimit,
        recent: data.recent,
        expiring: data.expiring,
      );
      await load(tester, FakeDocsTabRepository(full), visited: visited);
      await _tap(tester, find.bySemanticsLabel('Add a document'));
      expect(visited, isEmpty);
      expect(find.text(DocsCopy.limitSheet.headline), findsOneWidget);
    });

    testWidgets('premium is never stopped at the limit', (tester) async {
      final visited = <String>[];
      final data = populatedData();
      final full = DocsTabData(
        totalCount: kFreeDocumentLimit,
        recent: data.recent,
        expiring: data.expiring,
      );
      await load(
        tester,
        FakeDocsTabRepository(full),
        visited: visited,
        premium: true,
      );
      await _tap(tester, find.bySemanticsLabel('Add a document'));
      expect(visited, ['/documents/upload']);
    });

    for (final label in [
      'Add a document',
      'Scan with camera',
      'Closing disclosure',
    ]) {
      testWidgets('empty vault: "$label" opens the add flow', (tester) async {
        final visited = <String>[];
        await load(
          tester,
          FakeDocsTabRepository(const DocsTabData()),
          visited: visited,
        );
        await _tap(tester, find.text(label));
        expect(visited, ['/documents/upload']);
      });
    }
  });

  group('Docs tab responsive', () {
    testResponsiveLoaded(
      'populated',
      () => const DocumentsScreen(),
      wrap: (app) => _withRepo(FakeDocsTabRepository(populatedData()), app),
    );
    testResponsiveLoaded(
      'empty vault',
      () => const DocumentsScreen(),
      wrap: (app) => _withRepo(FakeDocsTabRepository(const DocsTabData()), app),
    );
    testResponsiveLoaded(
      'error',
      () => const DocumentsScreen(),
      wrap: (app) => _withRepo(
        FakeDocsTabRepository(populatedData())..failWith = StateError('x'),
        app,
      ),
    );
    testResponsiveLoaded(
      'loading',
      () => const DocumentsScreen(),
      wrap: (app) => _withRepo(
        FakeDocsTabRepository(populatedData(), gate: Completer<void>()),
        app,
      ),
    );
  });
}

Widget _withRepo(FakeDocsTabRepository repo, Widget app) =>
    ProviderScope(overrides: tabOverrides(repo), child: app);
