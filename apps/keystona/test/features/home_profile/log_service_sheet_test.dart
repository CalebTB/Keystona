import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keystona/features/home_profile/forms/log_service_form.dart';
import 'package:keystona/features/home_profile/models/item_ref.dart';
import 'package:keystona/features/home_profile/models/item_service_entry.dart';
import 'package:keystona/features/home_profile/providers/item_service_log_provider.dart';
import 'package:keystona/features/home_profile/widgets/service/log_service_sheet.dart';

import '../maintenance/tab/tasks_test_support.dart';
import 'support/fake_item_service_log_repository.dart';

const item = ItemRef.appliance('w1');

final existing = ItemServiceEntry(
  id: 'e1',
  item: item,
  kind: ServiceKind.repair,
  serviceDate: DateTime(2025, 6, 10),
  title: 'Replaced the inlet hoses',
  provider: 'Did it myself',
  cost: 34,
);

class Host extends ConsumerWidget {
  const Host({super.key, required this.editing, required this.results});

  final ItemServiceEntry? editing;
  final List<bool> results;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () async =>
            results.add(await LogServiceSheet.show(context, ref, item, editing: editing)),
        child: const Text('open'),
      ),
    ),
  );
}

Future<void> pumpHost(
  WidgetTester tester,
  FakeItemServiceLogRepository repo,
  List<bool> results, {
  ItemServiceEntry? editing,
}) async {
  phoneSurface(tester);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Host(editing: editing, results: results),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [itemServiceLogRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.tap(find.text('open'));
  await settle(tester);
}

void main() {
  testWidgets('adding saves through the log, returns true, host page stays', (
    tester,
  ) async {
    final repo = FakeItemServiceLogRepository();
    final results = <bool>[];
    await pumpHost(tester, repo, results);
    expect(find.text('Log a repair or service'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Annual tune-up');
    await tester.pump();
    await tester.ensureVisible(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(results, [true]);
    expect(repo.entries.single.title, 'Annual tune-up');
    expect(repo.entries.single.item, item);
    // Closed with its own context: the page beneath is still there.
    expect(find.text('open'), findsOneWidget);
    expect(find.text('Added to history.'), findsOneWidget);
  });

  testWidgets('Save waits for a title', (tester) async {
    final repo = FakeItemServiceLogRepository();
    await pumpHost(tester, repo, []);
    await tester.ensureVisible(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(repo.entries, isEmpty);
    expect(find.text('Log a repair or service'), findsOneWidget);
  });

  testWidgets('editing starts from the entry and updates it', (tester) async {
    final repo = FakeItemServiceLogRepository([existing]);
    final results = <bool>[];
    await pumpHost(tester, repo, results, editing: existing);
    expect(find.text('Edit this entry'), findsOneWidget);
    expect(find.text('Replaced the inlet hoses'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Replaced the inlet hoses'),
      'Replaced the hoses',
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(repo.calls, contains('update:e1'));
    expect(repo.entries.single.title, 'Replaced the hoses');
    expect(results, [true]);
    expect(find.text('History updated.'), findsOneWidget);
  });

  testWidgets('a failed write keeps the sheet open with an error', (tester) async {
    final repo = FakeItemServiceLogRepository()..failWrites = StateError('x');
    final results = <bool>[];
    await pumpHost(tester, repo, results);
    await tester.enterText(find.byType(TextField).first, 'Tune-up');
    await tester.pump();
    await tester.ensureVisible(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(results, isEmpty);
    expect(find.text("Couldn't save that entry. Try again."), findsOneWidget);
    expect(find.text('Log a repair or service'), findsOneWidget);
  });

  group('LogServiceForm', () {
    test('draft carries the trimmed fields; cost must be a number', () {
      final f = LogServiceForm(today: DateTime(2026, 10, 4));
      expect(f.canSave, isFalse);
      f.title.text = ' Tune-up ';
      f.provider.text = '';
      f.cost.text = '1,290.50';
      expect(f.canSave, isTrue);
      final d = f.toDraft();
      expect(d.title, 'Tune-up');
      expect(d.provider, isNull);
      expect(d.cost, 1290.5);
      expect(d.serviceDate, DateTime(2026, 10, 4));
      f.cost.text = 'free';
      expect(f.costInvalid, isTrue);
      expect(f.canSave, isFalse);
      f.dispose();
    });

    test('kinds are service and repair, plus the entry\'s own', () {
      expect(LogServiceForm().kinds, [ServiceKind.service, ServiceKind.repair]);
      final inst = ItemServiceEntry(
        id: 'i',
        item: item,
        kind: ServiceKind.installed,
        serviceDate: DateTime(2021),
        title: 'Installed',
      );
      expect(LogServiceForm(editing: inst).kinds.last, ServiceKind.installed);
    });
  });
}
