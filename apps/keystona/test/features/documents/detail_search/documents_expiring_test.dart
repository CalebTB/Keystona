import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/widgets/empty_state.dart';
import 'package:keystona/core/widgets/error_view.dart';
import 'package:keystona/features/documents/providers/document_repositories_provider.dart';
import 'package:keystona/features/documents/screens/documents_expiring_screen.dart';
import 'package:keystona/features/documents/widgets/expiring/expiring_skeleton.dart';

import '../../../support/responsive_harness.dart';
import 'detail_search_support.dart';

FakeExpiringRepository _repo({Completer<void>? gate}) => FakeExpiringRepository(
      [
        expiring('bath', 'Bath renovation permit', 32, category: 'Permit'),
        expiring('ins', 'Homeowners insurance policy', 8,
            provider: 'Statewide Mutual'),
        expiring('wash', 'Halden washer warranty', 65, category: 'Warranty'),
        expiring('term', 'Termite bond', 117, category: 'Contract'),
        expiring('old1', 'Calder water heater warranty', -400),
        expiring('old2', 'Previous homeowners policy', -300),
      ],
      gate: gate,
    );

List<Override> _overrides(FakeExpiringRepository repo) => [
      expiringDocumentsRepositoryProvider.overrideWithValue(repo),
    ];

Future<void> _open(WidgetTester tester, FakeExpiringRepository repo) async {
  await openScreen(tester, const DocumentsExpiringScreen(), _overrides(repo));
  await tester.pump();
}

double _top(WidgetTester tester, Finder f) => tester.getTopLeft(f).dy;

void main() {
  group('responsive', () {
    testResponsive(
      'expiring list',
      () => const DocumentsExpiringScreen(),
      wrap: (app) => scopeWrap(_overrides(_repo()), app),
    );

    testResponsive(
      'expiring skeleton',
      () => const DocumentsExpiringScreen(),
      wrap: (app) => scopeWrap(_overrides(_repo(gate: Completer<void>())), app),
    );

    testResponsive(
      'expiring empty',
      () => const DocumentsExpiringScreen(),
      wrap: (app) => scopeWrap(_overrides(FakeExpiringRepository([])), app),
    );
  });

  testWidgets('shows a skeleton on the first frame', (tester) async {
    await openScreen(
      tester,
      const DocumentsExpiringScreen(),
      _overrides(_repo(gate: Completer<void>())),
    );
    expect(find.byType(ExpiringSkeleton), findsOneWidget);
  });

  testWidgets('groups by urgency, soonest first, with the count in the header', (
    tester,
  ) async {
    await _open(tester, _repo());
    await tester.pump();

    expect(find.text('EVERYTHING WITH AN END DATE · 6'), findsOneWidget);
    expect(find.text('Expiring'), findsOneWidget);

    // Default range is 90 days: two bands, the 117-day bond is hidden.
    expect(find.text('NEXT 30 DAYS'), findsOneWidget);
    expect(find.text('NEXT 90 DAYS'), findsOneWidget);
    expect(find.text('LATER'), findsNothing);
    expect(find.text('Termite bond'), findsNothing);

    expect(
      _top(tester, find.text('NEXT 30 DAYS')) <
          _top(tester, find.text('NEXT 90 DAYS')),
      isTrue,
    );
    // Within the 90 band the earlier date comes first.
    expect(
      _top(tester, find.text('Bath renovation permit')) <
          _top(tester, find.text('Halden washer warranty')),
      isTrue,
    );
    expect(find.text('8 DAYS'), findsOneWidget);
    expect(find.text('32 DAYS'), findsOneWidget);
    expect(find.text('2 MONTHS'), findsOneWidget);
    expect(find.text('INSURANCE · STATEWIDE MUTUAL'), findsOneWidget);
  });

  testWidgets('only the inside-30-days card offers Upload renewal', (
    tester,
  ) async {
    await _open(tester, _repo());
    await tester.pump();

    expect(find.text('Upload renewal'), findsOneWidget);
  });

  testWidgets('what already ended is set apart and muted', (tester) async {
    await _open(tester, _repo());
    await tester.pump();

    expect(find.text('ALREADY ENDED · 2'), findsOneWidget);
    expect(find.textContaining('KEPT FOR YOUR RECORD'), findsNWidgets(2));
    expect(
      _top(tester, find.text('ALREADY ENDED · 2')) >
          _top(tester, find.text('Halden washer warranty')),
      isTrue,
    );
  });

  testWidgets('30 days narrows the list and All adds Later', (tester) async {
    await _open(tester, _repo());
    await tester.pump();

    await tester.tap(find.text('30 days'));
    await tester.pump();
    expect(find.text('NEXT 30 DAYS'), findsOneWidget);
    expect(find.text('NEXT 90 DAYS'), findsNothing);
    expect(find.text('Halden washer warranty'), findsNothing);

    await tester.tap(find.text('All'));
    await tester.pump();
    expect(find.text('NEXT 90 DAYS'), findsOneWidget);
    expect(find.text('LATER'), findsOneWidget);
    expect(find.text('Termite bond'), findsOneWidget);
    expect(find.text('1 YEAR'), findsNothing);
  });

  testWidgets('a card opens the document', (tester) async {
    await _open(tester, _repo());
    await tester.pump();

    await tester.tap(find.text('Halden washer warranty'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('detail wash'), findsOneWidget);
  });

  testWidgets('a failed load shows retry, and retry loads', (tester) async {
    final repo = _repo()..failures = 1;
    await _open(tester, repo);
    await tester.pump();

    expect(find.byType(ErrorView), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(ErrorView), findsNothing);
    expect(find.text('NEXT 30 DAYS'), findsOneWidget);
  });

  testWidgets('nothing with an end date shows the empty state', (tester) async {
    await _open(tester, FakeExpiringRepository([]));
    await tester.pump();

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Nothing has an end date'), findsOneWidget);
  });

  testWidgets('a range with nothing in it says so', (tester) async {
    final repo = FakeExpiringRepository([expiring('t', 'Termite bond', 200)]);
    await _open(tester, repo);
    await tester.pump();

    expect(find.text('Nothing ends in the next 90 days.'), findsOneWidget);
    expect(find.text('Termite bond'), findsNothing);
  });

  testWidgets('keeps the footer about reminders', (tester) async {
    await _open(tester, _repo());
    await tester.pump();

    expect(
      find.text('WE REMIND YOU 30 DAYS BEFORE EACH ONE · CHANGE IT IN SETTINGS'),
      findsOneWidget,
    );
  });
}
