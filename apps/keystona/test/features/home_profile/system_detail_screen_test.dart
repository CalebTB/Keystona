import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/home_profile/models/item_ref.dart';
import 'package:keystona/features/home_profile/models/item_service_entry.dart';
import 'package:keystona/features/home_profile/models/scan_prefill.dart';
import 'package:keystona/features/home_profile/models/system_detail.dart';
import 'package:keystona/features/home_profile/models/system_document.dart';
import 'package:keystona/features/home_profile/providers/warranty_check.dart';
import 'package:keystona/features/home_profile/screens/system_detail_screen.dart';
import 'package:keystona/features/maintenance/models/maintenance_task.dart';

import '../../support/responsive_harness.dart';
import '../maintenance/tab/tasks_test_support.dart';
import 'support/fake_item_service_log_repository.dart';
import 'support/fake_systems.dart';
import 'support/systems_harness.dart';

/// Tasks whose inserts show up in the next fetch, like the database.
class RecordingTasks extends FakeMaintenanceTasksRepository {
  RecordingTasks(super.tasks);

  final List<Map<String, dynamic>> inserted = [];

  @override
  Future<void> insertTask(Map<String, dynamic> fields) async {
    inserted.add(fields);
    tasks = [
      ...tasks,
      task(
        'wc',
        fields['name'] as String,
        due: DateTime.parse(fields['due_date'] as String),
      ).copyWith(
        linkedSystemId: fields['linked_system_id'] as String?,
        tags: List<String>.from(fields['tags'] as List),
      ),
    ];
  }
}

List<MaintenanceTask> furnaceTasks() => [
  for (final (i, name) in [
    'Replace HVAC air filter',
    'Service the furnace',
    'Test CO detector',
    'Vacuum vents',
    'Flush condensate',
  ].indexed)
    task('t$i', name, due: day(10, 7 + i * 7), minutes: 15)
        .copyWith(linkedSystemId: 'fu'),
];

final furnace = aSystem(
  'fu',
  installed: ago(years: 5, months: 6),
  replacementCost: 5800,
  warrantyExpiration: '2031-03-09',
  linkedWarrantyDocId: 'd1',
  specifications: {'fuel': 'Natural gas', 'output': '80,000 BTU'},
  purchasePrice: 4850,
).copyWith(serialNumber: '2103A47719', installer: 'Summit Heating & Air');

Future<List<Visit>> open(
  WidgetTester tester, {
  FakeSystemsRepository? systems,
  FakeMaintenanceTasksRepository? tasks,
  FakeItemServiceLogRepository? log,
  List<SystemDocument> docs = const [],
  SystemPhotoSummary photos = const SystemPhotoSummary(count: 4),
}) async {
  tester.view.physicalSize = const Size(390, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final visits = <Visit>[];
  await tester.pumpWidget(
    HomeRoutedApp(
      home: const SystemDetailScreen(systemId: 'fu'),
      visits: visits,
      overrides: homeOverrides(
        systems: systems ?? FakeSystemsRepository([furnace]),
        tasks: tasks ?? FakeMaintenanceTasksRepository(furnaceTasks()),
        log: log,
        documents: FakeSystemDocumentsRepository(docs),
        photos: FakeSystemPhotosRepository(summaryValue: photos),
      ),
    ),
  );
  await settle(tester);
  return visits;
}

void main() {
  testWidgets('shows the kit furnace: header, lifespan, tasks, ID, warranty', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Furnace'), findsOneWidget);
    expect(find.text('HVAC · SYSTEM'), findsOneWidget);
    expect(find.text('HEALTHY'), findsOneWidget);
    expect(find.text('Northline NF95-080B · Basement utility room'), findsOneWidget);
    expect(find.text('4 PHOTOS'), findsOneWidget);
    expect(find.textContaining('5½ yrs', findRichText: true), findsWidgets);
    expect(find.textContaining('9½ years left', findRichText: true), findsOneWidget);
    expect(find.text('NEXT UP · 2'), findsOneWidget);
    expect(find.text('All 5 HVAC tasks ›'), findsOneWidget);
    expect(find.text('Replace HVAC air filter'), findsOneWidget);
    expect(find.text('Test CO detector'), findsNothing);
    expect(find.text('2103A47719'), findsOneWidget);
    expect(find.text('Natural gas'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
    // No check callout: the warranty is years away.
    expect(find.textContaining('WARRANTY ENDS IN'), findsNothing);
  });

  testWidgets('Edit sits at the right edge and opens edit mode with the system', (
    tester,
  ) async {
    final visits = await open(tester);
    expect(tester.getTopRight(find.text('Edit')).dx, greaterThan(330));
    await tester.tap(find.text('Edit'));
    await settle(tester);
    expect(visits.single.path, '/home/systems/add');
    final args = visits.single.extra as ItemFormArgs;
    expect(args.existingSystem?.id, 'fu');
  });

  testWidgets('history shows costs at the right, the install row last', (
    tester,
  ) async {
    final log = FakeItemServiceLogRepository([
      ItemServiceEntry(
        id: 'e1',
        item: const ItemRef.system('fu'),
        kind: ServiceKind.service,
        serviceDate: DateTime(2025, 10, 1),
        title: 'Annual tune-up',
        provider: 'Summit Heating & Air',
        cost: 129,
        documentId: 'd9',
      ),
    ]);
    await open(tester, log: log);
    expect(find.text('HISTORY · 2'), findsOneWidget);
    expect(find.text(r'$4,979 SINCE 2021'), findsOneWidget);
    expect(find.text('Annual tune-up'), findsOneWidget);
    expect(find.text('Installed'), findsOneWidget);
    expect(tester.getTopRight(find.text(r'$129')).dx, greaterThan(330));
    expect(
      tester.getTopLeft(find.text('Annual tune-up')).dy,
      lessThan(tester.getTopLeft(find.text('Installed')).dy),
    );
  });

  testWidgets('Log a repair or service saves through the log and closes', (
    tester,
  ) async {
    final log = FakeItemServiceLogRepository();
    await open(tester, log: log);
    await tester.tap(find.text('Log a repair or service'));
    await settle(tester);
    expect(find.textContaining('WHAT WAS DONE', findRichText: true), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Replaced the igniter');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(log.calls, contains('add'));
    expect(log.entries.single.title, 'Replaced the igniter');
    expect(find.textContaining('WHAT WAS DONE', findRichText: true), findsNothing);
    expect(find.text('Replaced the igniter'), findsOneWidget);
    expect(find.text('Added to history.'), findsOneWidget);
  });

  testWidgets('no history yet shows the catalog note and the install row', (
    tester,
  ) async {
    final bare = aSystem('fu', installed: null);
    await open(tester, systems: FakeSystemsRepository([bare]));
    expect(find.text('No service history yet'), findsOneWidget);
    expect(find.text('HISTORY · 0'), findsOneWidget);
    expect(find.text('Add the install date to see how much life is left.'), findsOneWidget);
  });

  testWidgets('documents list with meta and open the document', (tester) async {
    final visits = await open(
      tester,
      docs: [
        SystemDocument(
          id: 'd1',
          name: 'Northline warranty',
          createdAt: DateTime(2021, 3),
          categoryName: 'Warranty',
          mimeType: 'application/pdf',
          expirationDate: DateTime(2031, 3, 9),
        ),
      ],
    );
    expect(find.text('DOCUMENTS · 1'), findsOneWidget);
    expect(find.text('WARRANTY · PDF · UNTIL MAR 2031'), findsOneWidget);
    await tester.tap(find.text('Northline warranty').last);
    await settle(tester);
    expect(visits.single.path, '/documents/d1');
  });

  testWidgets('the photo badge and All tasks open the item screens', (tester) async {
    final visits = await open(tester);
    await tester.tap(find.text('4 PHOTOS'));
    await settle(tester);
    expect(visits.last.path, '/home/systems/fu/photos');
  });

  testWidgets('a warranty ending soon offers a check; tapping adds the task', (
    tester,
  ) async {
    final soon = DateTime.now().add(const Duration(days: 40));
    final end =
        '${soon.year}-${soon.month.toString().padLeft(2, '0')}-${soon.day.toString().padLeft(2, '0')}';
    final tasks = RecordingTasks(furnaceTasks());
    await open(
      tester,
      systems: FakeSystemsRepository([
        aSystem('fu', installed: ago(years: 5), warrantyExpiration: end),
      ]),
      tasks: tasks,
    );
    expect(find.text('WARRANTY ENDS IN 40 DAYS'), findsOneWidget);
    await tester.tap(find.textContaining('Add a check before'));
    await settle(tester);
    expect(tasks.inserted.single['tags'], [WarrantyCheck.tag]);
    expect(tasks.inserted.single['linked_system_id'], 'fu');
    expect(find.textContaining('✓ Added to Tasks'), findsOneWidget);
  });

  testWidgets('a failed load shows the error', (tester) async {
    final repo = FakeSystemsRepository(const []);
    await open(tester, systems: repo);
    expect(find.text("Couldn't load this system."), findsOneWidget);
  });

  testResponsive(
    'furnace detail does not overflow',
    () => const SystemDetailScreen(systemId: 'fu'),
    wrap: (app) => ProviderScopeForDetail.wrap(app),
  );

  group('WarrantyCheck', () {
    test('due a fortnight before the end, never in the past', () {
      final today = DateTime(2026, 10, 4);
      expect(
        WarrantyCheck.dueDate(DateTime(2026, 12, 9), today),
        DateTime(2026, 11, 25),
      );
      expect(WarrantyCheck.dueDate(DateTime(2026, 10, 10), today), today);
    });

    test('finds its task by tag and system', () {
      final a = task('a', 'x', due: day(10, 7))
          .copyWith(linkedSystemId: 'fu', tags: [WarrantyCheck.tag]);
      final b = task('b', 'y', due: day(10, 7)).copyWith(linkedSystemId: 'fu');
      expect(WarrantyCheck.taskFor([b, a], 'fu')?.id, 'a');
      expect(WarrantyCheck.taskFor([a], 'other'), isNull);
    });
  });
}

abstract final class ProviderScopeForDetail {
  static Widget wrap(Widget app) => ProviderScope(
    overrides: homeOverrides(
      systems: FakeSystemsRepository([furnace]),
      tasks: FakeMaintenanceTasksRepository(furnaceTasks()),
      photos: FakeSystemPhotosRepository(
        summaryValue: const SystemPhotoSummary(count: 4),
      ),
    ),
    child: app,
  );
}
