import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/router/app_router.dart';
import 'package:keystona/core/widgets/error_view.dart';
import 'package:keystona/features/home_profile/models/item_ref.dart';
import 'package:keystona/features/home_profile/models/item_service_entry.dart';
import 'package:keystona/features/home_profile/models/scan_prefill.dart';
import 'package:keystona/features/home_profile/screens/appliance_detail_screen.dart';
import 'package:keystona/features/home_profile/widgets/service/log_service_body.dart';
import 'package:keystona/features/maintenance/providers/task_repositories_provider.dart';

import '../../maintenance/detail/task_detail_test_support.dart'
    show FakeTaskDetailRepository, fixtureDetail;
import '../../maintenance/form_reminders/form_reminders_support.dart'
    show testResponsiveLoaded;
import '../support/fake_item_service_log_repository.dart';
import 'c_support.dart';

const ApplianceDetailScreen screen = ApplianceDetailScreen(applianceId: 'wa');

/// A phone as wide as the reference one, tall enough for the whole page.
const Size tall = Size(390, 3200);

FakeItemServiceLogRepository hoses() => FakeItemServiceLogRepository([
  ItemServiceEntry(
    id: 'h',
    item: const ItemRef.appliance('wa'),
    kind: ServiceKind.repair,
    serviceDate: DateTime(2025, 6, 10),
    title: 'Replaced the inlet hoses',
    provider: 'Did it myself',
    note: 'steel-braided',
    cost: 34,
  ),
]);

List<dynamic> kitOverrides({RecordingTasksRepository? tasks}) => cOverrides(
  tasks:
      tasks ??
      RecordingTasksRepository([
        washerTask('g', 'Wipe the door gasket', due: day(10, 19), minutes: 5),
        washerTask('d', 'Clean the drain filter', due: day(1, 18, 2027), minutes: 20),
        washerTask('h', 'Descale', due: day(3, 1, 2027)),
        washerTask('i', 'Check hoses', due: day(4, 1, 2027)),
      ]),
  photos: FakeItemPhotosRepository([aPhoto('p1'), aPhoto('p2', type: 'label'), aPhoto('p3')]),
  log: hoses(),
  documents: FakeItemDocumentsRepository([
    aDoc('d1', 'Washer warranty', type: 'Warranty', expires: DateTime(2026, 12, 9)),
    aDoc('d2', 'Receipt', type: 'Receipt'),
    aDoc('d3', "Owner's manual", type: 'Manual', pages: 64),
  ]),
);

void main() {
  testWidgets('shows the kit detail, top to bottom', (tester) async {
    await openScreen(tester, screen, size: tall, overrides: kitOverrides().cast());
    expect(find.text('LAUNDRY · APPLIANCE'), findsOneWidget);
    expect(find.text('HEALTHY'), findsOneWidget);
    expect(find.text('Washer'), findsWidgets);
    expect(find.text('Halden HW45-FL2 · Laundry room'), findsOneWidget);
    expect(find.text('WARRANTY ENDS IN 66 DAYS'), findsOneWidget);
    expect(find.text('Covered until Dec 9.'), findsOneWidget);
    expect(find.text('Add a check before Dec 9'), findsOneWidget);
    expect(find.text('3 PHOTOS'), findsOneWidget);
    expect(find.text('UNIT'), findsOneWidget);
    expect(find.textContaining('3 yrs'), findsWidgets);
    expect(find.text('BOUGHT DEC 2023'), findsOneWidget);
    expect(find.text('REPLACE AROUND 2034'), findsOneWidget);
    expect(find.textContaining('About 8 years left.'), findsOneWidget);
    expect(find.textContaining('Front-loaders last longest'), findsOneWidget);
    expect(find.text('NEXT UP · 2'), findsOneWidget);
    expect(find.text('Wipe the door gasket'), findsOneWidget);
    expect(find.text('Check hoses'), findsNothing);
    expect(find.text('All 4 appliance tasks'), findsOneWidget);
    expect(find.text('PURCHASE'), findsOneWidget);
    expect(find.text('Brightway Appliance'), findsNWidgets(2));
    expect(find.text('IDENTIFICATION'), findsOneWidget);
    expect(find.text('HL3390218K'), findsOneWidget);
    expect(find.text('SPECIFICATIONS · 5'), findsOneWidget);
    expect(find.text('Certified'), findsOneWidget);
    expect(find.text('HISTORY · 2'), findsOneWidget);
    expect(find.text('\$883 SINCE 2023'), findsOneWidget);
    expect(find.text('Replaced the inlet hoses'), findsOneWidget);
    expect(find.text('Bought'), findsOneWidget);
    expect(find.text('Log a repair or service'), findsOneWidget);
    expect(find.text('DOCUMENTS · 3'), findsOneWidget);
    expect(find.text('WARRANTY · PDF · ENDS DEC 9'), findsOneWidget);
    expect(find.text('MANUAL · PDF · 64 PAGES'), findsOneWidget);
  });

  testWidgets('Edit sits at the right edge and opens the form with the appliance', (
    tester,
  ) async {
    final visits = await openScreen(tester, screen, size: tall, overrides: kitOverrides().cast());
    final edit = find.text('Edit');
    expect(tester.getTopRight(edit).dx, greaterThan(390 - 40));
    await tester.tap(edit);
    await settle(tester);
    expect(visits.single.path, AppRoutes.homeAppliancesAdd);
    final args = visits.single.extra as ItemFormArgs;
    expect(args.existingAppliance?.id, 'wa');
  });

  testWidgets('"All 4 appliance tasks" opens the item tasks, the badge the photos', (
    tester,
  ) async {
    var visits = await openScreen(tester, screen, size: tall, overrides: kitOverrides().cast());
    await tester.tap(find.text('All 4 appliance tasks'));
    await settle(tester);
    expect(visits.single.path, '/home/appliances/wa/tasks');

    visits = await openScreen(tester, screen, size: tall, overrides: kitOverrides().cast());
    await tester.tap(find.text('3 PHOTOS'));
    await settle(tester);
    expect(visits.single.path, '/home/appliances/wa/photos');
  });

  testWidgets('the warranty button adds a one-off check and says so; a second tap takes it back', (
    tester,
  ) async {
    final tasks = RecordingTasksRepository([]);
    final detail = FakeTaskDetailRepository(fixtureDetail());
    await openScreen(
      tester,
      screen,
      size: tall,
      overrides: [
        ...kitOverrides(tasks: tasks).cast(),
        taskDetailRepositoryProvider.overrideWithValue(detail),
      ],
    );
    await tester.tap(find.text('Add a check before Dec 9'));
    await settle(tester);
    expect(tasks.inserted.single['due_date'], '2026-11-25');
    expect(tasks.inserted.single['linked_appliance_id'], 'wa');
    expect(tasks.inserted.single['user_id'], 'u1');
    expect(find.text('✓ Added to Tasks · Nov 25'), findsOneWidget);

    await tester.tap(find.text('✓ Added to Tasks · Nov 25'));
    await settle(tester);
    expect(detail.deletedTasks, ['warranty1']);
  });

  testWidgets('no callout when the warranty is far off', (tester) async {
    final repo = FakeAppliancesRepository([
      anAppliance('wa', 'Washer', purchaseDate: '2023-12-09', life: 11, warrantyEnds: '2028-12-09'),
    ]);
    await openScreen(tester, screen, overrides: cOverrides(appliances: repo));
    expect(find.textContaining('WARRANTY ENDS IN'), findsNothing);
  });

  testWidgets('"Log a repair or service" opens the shared sheet', (tester) async {
    await openScreen(tester, screen, size: tall, overrides: kitOverrides().cast());
    await tester.tap(find.text('Log a repair or service'));
    await settle(tester);
    expect(find.byType(LogServiceBody), findsOneWidget);
  });

  testWidgets('Specifications collapse and open', (tester) async {
    await openScreen(tester, screen, size: tall, overrides: kitOverrides().cast());
    expect(find.text('Certified'), findsOneWidget);
    await tester.tap(find.text('HIDE'));
    await settle(tester);
    expect(find.text('Certified'), findsNothing);
    await tester.tap(find.text('SHOW'));
    await settle(tester);
    expect(find.text('Certified'), findsOneWidget);
  });

  testWidgets('no purchase date asks for it instead of a lifespan', (tester) async {
    final repo = FakeAppliancesRepository([anAppliance('wa', 'Washer', life: 11)]);
    await openScreen(tester, screen, overrides: cOverrides(appliances: repo));
    expect(find.text('Add the purchase date to see how much life is left.'), findsOneWidget);
  });

  testWidgets('a deleted appliance says it cannot be found', (tester) async {
    final repo = FakeAppliancesRepository(const []);
    await openScreen(tester, screen, overrides: cOverrides(appliances: repo));
    expect(find.text('We can’t find that appliance'), findsOneWidget);
  });

  testWidgets('a failed load offers Try again', (tester) async {
    final repo = FakeAppliancesRepository(kitAppliances())..listError = StateError('x');
    await openScreen(tester, screen, overrides: cOverrides(appliances: repo));
    expect(find.byType(ErrorView), findsOneWidget);
    repo.listError = null;
    await tester.tap(find.text('Try again'));
    await settle(tester);
    expect(find.text('LAUNDRY · APPLIANCE'), findsOneWidget);
  });

  testResponsiveLoaded(
    'the detail holds up',
    () => screen,
    overrides: () => kitOverrides().cast(),
  );
}
