import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/router/app_router.dart';
import 'package:keystona/core/widgets/empty_state.dart';
import 'package:keystona/core/widgets/error_view.dart';
import 'package:keystona/core/widgets/loading_skeleton_card.dart';
import 'package:keystona/features/home_profile/models/appliance_suggestion.dart';
import 'package:keystona/features/home_profile/models/item_ref.dart';
import 'package:keystona/features/home_profile/screens/appliances_screen.dart';

import '../../maintenance/form_reminders/form_reminders_support.dart' show testResponsiveLoaded;
import 'c_support.dart';

AppliancesScreen screen() => AppliancesScreen(today: kToday);

void main() {
  testWidgets('shows the kit list: eyebrow, rows oldest first, task counts', (
    tester,
  ) async {
    final tasks = FakeMaintenanceTasksRepository([
      washerTask('t1', 'Wipe gasket', due: day(10, 19)),
      washerTask('t2', 'Clean filter', due: day(1, 18, 2027)),
      task('t3', 'Dish', due: day(10, 9)).copyWith(linkedApplianceId: 'dw'),
    ]);
    await openScreen(tester, screen(), overrides: cOverrides(tasks: tasks));
    expect(find.text('1428 ELM HOLLOW LN · 5 TRACKED · 1 PAST ITS LIFE'), findsOneWidget);
    expect(find.text('Appliances'), findsOneWidget);
    expect(find.text('All 5'), findsOneWidget);
    expect(find.text('Kitchen'), findsOneWidget);
    expect(find.text('Laundry'), findsOneWidget);
    expect(find.text('5 SHOWN'), findsOneWidget);
    expect(find.text('Brennan DW24 · Kitchen'), findsOneWidget);
    expect(find.text('PAST EXPECTED LIFE'), findsOneWidget);
    expect(find.text('REPLACE ~2030'), findsOneWidget);
    expect(find.text('WARRANTY ENDS DEC 9'), findsOneWidget);
    expect(find.text('2 TASKS'), findsOneWidget);
    expect(find.text('1 TASK'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Dishwasher')).dy,
      lessThan(tester.getTopLeft(find.text('Refrigerator')).dy),
    );
    expect(find.text('OFTEN FORGOTTEN'), findsOneWidget);
    expect(find.text('Scan a label to add one'), findsOneWidget);
  });

  testWidgets('a category chip narrows the list and A-Z reorders it', (
    tester,
  ) async {
    await openScreen(tester, screen());
    await tester.tap(find.text('Laundry'));
    await settle(tester);
    expect(find.text('2 SHOWN'), findsOneWidget);
    expect(find.text('Dishwasher'), findsNothing);
    expect(find.text('Washer'), findsOneWidget);
    await tester.tap(find.text('All 5'));
    await tester.tap(find.text('A–Z'));
    await settle(tester);
    expect(
      tester.getTopLeft(find.text('Dryer')).dy,
      lessThan(tester.getTopLeft(find.text('Range')).dy),
    );
  });

  testWidgets('+ Add sits at the right edge and opens the scan for appliances', (
    tester,
  ) async {
    final visits = await openScreen(tester, screen());
    final add = find.text('+ Add');
    expect(tester.getTopRight(add).dx, greaterThan(390 - 40));
    await tester.tap(add);
    await settle(tester);
    expect(visits.single.path, AppRoutes.homeScan);
    expect(visits.single.extra, ItemKind.appliance);
  });

  testWidgets('a row opens its appliance; a chip opens Add with it filled', (
    tester,
  ) async {
    var visits = await openScreen(tester, screen());
    await tester.tap(find.text('Washer'));
    await settle(tester);
    expect(visits.single.path, '/home/appliances/wa');

    visits = await openScreen(tester, screen());
    await tester.ensureVisible(find.text('Microwave'));
    await tester.pump();
    await tester.tap(find.text('Microwave'));
    await settle(tester);
    expect(visits.single.path, AppRoutes.homeAppliancesAdd);
    expect((visits.single.extra as ApplianceSuggestion).name, 'Microwave');
  });

  testWidgets('loading shows skeletons shaped like rows', (tester) async {
    final gate = Completer<void>();
    final repo = FakeAppliancesRepository(kitAppliances(), gate: gate);
    await openScreen(tester, screen(), overrides: cOverrides(appliances: repo));
    expect(find.byType(LoadingSkeletonCard), findsNWidgets(3));
    gate.complete();
    await settle(tester);
    expect(find.byType(LoadingSkeletonCard), findsNothing);
  });

  testWidgets('an error offers Try again, which reloads', (tester) async {
    final repo = FakeAppliancesRepository(kitAppliances())
      ..listError = StateError('offline');
    await openScreen(tester, screen(), overrides: cOverrides(appliances: repo));
    expect(find.byType(ErrorView), findsOneWidget);
    repo.listError = null;
    await tester.tap(find.text('Try again'));
    await settle(tester);
    expect(find.text('Dishwasher'), findsOneWidget);
  });

  testWidgets('with no appliances it invites the first one', (tester) async {
    final repo = FakeAppliancesRepository(const []);
    final visits = await openScreen(
      tester,
      screen(),
      overrides: cOverrides(appliances: repo),
    );
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('No appliances yet'), findsOneWidget);
    await tester.tap(find.text('Add an appliance'));
    await settle(tester);
    expect(visits.single.path, AppRoutes.homeAppliancesAdd);
  });

  testResponsiveLoaded(
    'the list holds up',
    screen,
    overrides: () => cOverrides(),
  );
}
