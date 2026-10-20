import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/widgets/error_view.dart';
import 'package:keystona/features/documents/screens/document_search_screen.dart';
import 'package:keystona/features/documents/widgets/search/search_premium_gate.dart';
import 'package:keystona/features/documents/widgets/search/search_skeleton.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/responsive_harness.dart';
import 'detail_search_support.dart';

const Duration _debounce = Duration(milliseconds: 300);

FakeSearchRepository _repo() => FakeSearchRepository(
      hits: [
        hit('d1', 'Dryer owner manual'),
        hit('d2', 'Washer owner manual'),
        hit('d3', 'Roof 20-year warranty', expiration: daysFromNow(2000)),
        hit('d4', 'Homeowners insurance policy', expiration: daysFromNow(9)),
      ],
    );

Future<void> _open(
  WidgetTester tester,
  FakeSearchRepository repo, {
  bool premium = false,
  DocumentSearchScreen screen = const DocumentSearchScreen(),
}) async {
  await openScreen(
    tester,
    screen,
    searchOverrides(repository: repo, premium: premium),
  );
  await tester.pump();
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({
        'documents_recent_searches': ['roof', 'manual', 'closing'],
      }));

  group('responsive', () {
    testResponsive(
      'search start',
      () => const DocumentSearchScreen(),
      wrap: (app) => scopeWrap(searchOverrides(repository: _repo()), app),
    );

    testResponsive(
      'search results with gate',
      () => const DocumentSearchScreen(initialQuery: 'manual'),
      wrap: (app) => scopeWrap(searchOverrides(repository: _repo()), app),
    );

    testResponsive(
      'search results scoped to a category, premium',
      () => const DocumentSearchScreen(
        initialQuery: 'manual',
        initialCategoryId: 'c-war',
      ),
      wrap: (app) => scopeWrap(
        searchOverrides(repository: _repo(), premium: true),
        app,
      ),
    );
  });

  testWidgets('start shows categories with counts and recent searches', (
    tester,
  ) async {
    await _open(tester, _repo());
    await tester.pump();

    expect(find.text('SEARCH IN'), findsOneWidget);
    expect(find.text('Insurance'), findsOneWidget);
    expect(find.text('Warranties & manuals'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('RECENT'), findsOneWidget);
    expect(find.text('roof'), findsOneWidget);
    expect(find.text('manual'), findsOneWidget);
    expect(find.text('closing'), findsOneWidget);
    expect(find.text('Search name or category'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('picking a category scopes the search and shows its token', (
    tester,
  ) async {
    final repo = _repo();
    await _open(tester, repo);
    await tester.pump();

    await tester.tap(find.text('Warranties & manuals'));
    await tester.pump();
    await tester.pump(_debounce);
    await tester.pump();

    expect(repo.queries.last.categoryId, 'c-war');
    expect(find.text('Search warranties & manuals'), findsOneWidget);
    expect(find.text('4 RESULTS IN WARRANTIES & MANUALS'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump();
    expect(find.text('SEARCH IN'), findsOneWidget);
  });

  testWidgets('typing is debounced to one search after 300 ms', (tester) async {
    final repo = _repo();
    await _open(tester, repo);
    await tester.pump();
    final before = repo.queries.length;

    await _type(tester, 'm');
    await tester.pump(const Duration(milliseconds: 100));
    await _type(tester, 'ma');
    await tester.pump(const Duration(milliseconds: 100));
    await _type(tester, 'man');
    await tester.pump(const Duration(milliseconds: 200));

    // Still waiting: nothing has been searched yet and a skeleton shows.
    expect(repo.queries.length, before);
    expect(find.byType(SearchSkeleton), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();

    expect(repo.queries.length, before + 1);
    expect(repo.queries.last.text, 'man');
    expect(find.text('2 RESULTS'), findsOneWidget);
    expect(find.byType(SearchSkeleton), findsNothing);
  });

  testWidgets('results underline the match and show the date and status', (
    tester,
  ) async {
    await _open(
      tester,
      _repo(),
      screen: const DocumentSearchScreen(initialQuery: 'o'),
    );
    await tester.pump();

    expect(find.textContaining('Dryer owner manual'), findsOneWidget);
    expect(find.text('9 DAYS'), findsOneWidget);
    expect(find.text('TO ${daysFromNow(2000).year}'), findsOneWidget);
    expect(find.textContaining('WARRANTIES · JAN 28'), findsWidgets);
  });

  testWidgets('free accounts see the Premium gate and it opens the upgrade sheet', (
    tester,
  ) async {
    final repo = _repo();
    await _open(
      tester,
      repo,
      screen: const DocumentSearchScreen(initialQuery: 'manual'),
    );
    await tester.pump();

    expect(find.byType(SearchPremiumGate), findsOneWidget);
    expect(find.text('Search inside your documents'), findsOneWidget);
    expect(
      find.text('Premium also finds “manual” in the text of your PDFs and photos.'),
      findsOneWidget,
    );
    expect(repo.fullTextFlags.last, isFalse);

    await tester.tap(find.byType(SearchPremiumGate));
    await tester.pumpAndSettle();
    expect(find.text('WITH PREMIUM, YOU GET'), findsOneWidget);
  });

  testWidgets('Premium searches inside files and shows snippets, no gate', (
    tester,
  ) async {
    final repo = FakeSearchRepository(
      hits: [
        hit(
          'd1',
          'Dryer owner manual',
          snippet: 'Clean the **lint** trap after every load',
        ),
      ],
    );
    await _open(
      tester,
      repo,
      premium: true,
      screen: const DocumentSearchScreen(initialQuery: 'dryer'),
    );
    await tester.pump();

    expect(repo.fullTextFlags.last, isTrue);
    expect(find.byType(SearchPremiumGate), findsNothing);
    expect(
      find.textContaining('Clean the lint trap after every load'),
      findsOneWidget,
    );
  });

  testWidgets('no match explains what free search covers', (tester) async {
    await _open(
      tester,
      _repo(),
      screen: const DocumentSearchScreen(initialQuery: 'zzz'),
    );
    await tester.pump();

    expect(find.text('No documents match “zzz”'), findsOneWidget);
    expect(
      find.textContaining('Free search checks document names and categories'),
      findsOneWidget,
    );
  });

  testWidgets('a failed search shows retry and retry searches again', (
    tester,
  ) async {
    final repo = _repo()..failures = 1;
    await _open(
      tester,
      repo,
      screen: const DocumentSearchScreen(initialQuery: 'manual'),
    );
    await tester.pump();

    expect(find.byType(ErrorView), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(ErrorView), findsNothing);
    expect(find.text('2 RESULTS'), findsOneWidget);
  });

  testWidgets('tapping a recent search runs it', (tester) async {
    final repo = _repo();
    await _open(tester, repo);
    await tester.pump();

    await tester.tap(find.text('manual'));
    await tester.pump();
    await tester.pump();

    expect(repo.queries.last.text, 'manual');
    expect(find.text('2 RESULTS'), findsOneWidget);
  });

  testWidgets('opening a result remembers the search and opens the document', (
    tester,
  ) async {
    await _open(
      tester,
      _repo(),
      screen: const DocumentSearchScreen(initialQuery: 'manual'),
    );
    await tester.pump();

    await tester.tap(find.textContaining('Dryer owner manual'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('detail d1'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('documents_recent_searches')!.first, 'manual');
  });

  testWidgets('Cancel leaves the screen', (tester) async {
    await _open(tester, _repo());
    await tester.pump();

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(kPushTransition);

    expect(find.text('HOME'), findsOneWidget);
  });
}
