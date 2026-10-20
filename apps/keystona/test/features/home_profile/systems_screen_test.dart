import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/home_profile/models/item_ref.dart';
import 'package:keystona/features/home_profile/models/system_template.dart';
import 'package:keystona/features/home_profile/screens/systems_screen.dart';

import '../../support/responsive_harness.dart';
import '../maintenance/tab/tasks_test_support.dart';
import 'support/fake_systems.dart';
import 'support/systems_harness.dart';

/// Scrolls [finder] into view and lets the scroll finish.
Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 500));
}

Future<List<Visit>> open(
  WidgetTester tester, {
  FakeSystemsRepository? systems,
  FakeMaintenanceTasksRepository? tasks,
  bool online = true,
}) async {
  phoneSurface(tester);
  final visits = <Visit>[];
  await tester.pumpWidget(
    HomeRoutedApp(
      home: const SystemsScreen(),
      visits: visits,
      overrides: homeOverrides(
        systems: systems ?? FakeSystemsRepository(kitSystems()),
        tasks: tasks,
        online: online,
      ),
    ),
  );
  await settle(tester);
  return visits;
}

void main() {
  testWidgets('shows the kit list: eyebrow, rows oldest first, task counts', (
    tester,
  ) async {
    final tasks = FakeMaintenanceTasksRepository([
      task('t1', 'Flush', due: day(10, 7)).copyWith(linkedSystemId: 'wh'),
      task('t2', 'Check', due: day(10, 8)).copyWith(linkedSystemId: 'wh'),
      task('t3', 'Test', due: day(10, 9)).copyWith(linkedSystemId: 'ep'),
    ]);
    await open(tester, tasks: tasks);
    expect(find.text('1428 ELM HOLLOW · 5 TRACKED · 1 AGING'), findsOneWidget);
    expect(find.text('Systems'), findsOneWidget);
    expect(find.text('All 5'), findsOneWidget);
    expect(find.text('5 SHOWN'), findsOneWidget);
    expect(find.text('AT END OF LIFE'), findsOneWidget);
    expect(find.text('2 TASKS'), findsOneWidget);
    expect(find.text('1 TASK'), findsOneWidget);
    // Oldest first: the water heater sits above the furnace.
    expect(
      tester.getTopLeft(find.text('Water heater')).dy,
      lessThan(tester.getTopLeft(find.text('Furnace')).dy),
    );
    expect(find.text('COMMON IN A 1998 HOME, NOT TRACKED YET'), findsOneWidget);
  });

  testWidgets('+ Add sits at the right edge and opens the scan with system', (
    tester,
  ) async {
    final visits = await open(tester);
    final add = find.text('+ Add');
    expect(tester.getTopRight(add).dx, greaterThan(300));
    expect(tester.getTopLeft(find.text('Home profile')).dx, lessThan(60));
    await tester.tap(add);
    await settle(tester);
    expect(visits.single.path, '/home/scan');
    expect(visits.single.extra, ItemKind.system);
  });

  testWidgets('a filter chip narrows the list; A-Z reorders', (tester) async {
    await open(tester);
    await reveal(tester, find.text('Water'));
    await tester.tap(find.text('Water'));
    await tester.pump();
    expect(find.text('1 SHOWN'), findsOneWidget);
    expect(find.text('Water heater'), findsOneWidget);
    expect(find.text('Furnace'), findsNothing);
    await reveal(tester, find.text('All 5'));
    await tester.tap(find.text('All 5'));
    await tester.pump();
    await tester.tap(find.text('A–Z'));
    await tester.pump();
    expect(
      tester.getTopLeft(find.text('Central AC')).dy,
      lessThan(tester.getTopLeft(find.text('Water heater')).dy),
    );
  });

  testWidgets('a row opens its detail', (tester) async {
    final visits = await open(tester);
    await tester.tap(find.text('Furnace'));
    await settle(tester);
    expect(visits.single.path, '/home/systems/fu');
  });

  testWidgets('a suggestion chip opens Add system filled from its template', (
    tester,
  ) async {
    final visits = await open(tester);
    await reveal(tester, find.text('Windows'));
    await tester.tap(find.text('Windows'));
    await settle(tester);
    expect(visits.single.path, '/home/systems/add');
    expect((visits.single.extra as SystemTemplate).label, 'Windows');
  });

  testWidgets('the scan button says so offline instead of opening', (
    tester,
  ) async {
    final visits = await open(tester, online: false);
    await reveal(tester, find.text('Scan a label to add one'));
    await tester.tap(find.text('Scan a label to add one'));
    await settle(tester);
    expect(visits, isEmpty);
    expect(find.textContaining("You're offline"), findsOneWidget);
  });

  testWidgets('no systems shows the catalog empty state', (tester) async {
    await open(tester, systems: FakeSystemsRepository(const []));
    expect(find.text("Add your home's systems"), findsOneWidget);
    expect(find.text('+ Add First System'), findsOneWidget);
  });

  testWidgets('a failed load shows the error with Retry', (tester) async {
    final repo = FakeSystemsRepository(kitSystems())..failList = StateError('x');
    await open(tester, systems: repo);
    expect(find.text("Couldn't load your systems."), findsOneWidget);
    repo.failList = null;
    await tester.tap(find.text('Try again'));
    await settle(tester);
    expect(find.text('Furnace'), findsOneWidget);
  });

  testResponsive(
    'kit list does not overflow',
    () => const SystemsScreen(),
    wrap: (app) => ProviderScopeFor.wrap(app, kitSystems()),
  );
}
