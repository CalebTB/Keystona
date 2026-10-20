import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keystona/features/maintenance/models/completion_photo.dart';
import 'package:keystona/features/maintenance/models/maintenance_task.dart';
import 'package:keystona/features/maintenance/models/task_completion.dart';
import 'package:keystona/features/maintenance/models/task_detail.dart';
import 'package:keystona/features/maintenance/models/task_log_draft.dart';
import 'package:keystona/features/maintenance/models/task_parent.dart';
import 'package:keystona/features/maintenance/models/task_skip.dart';
import 'package:keystona/features/maintenance/providers/task_repositories_provider.dart';
import 'package:keystona/features/maintenance/repositories/task_detail_repository.dart';
import 'package:keystona/features/maintenance/screens/task_detail_screen.dart';
import 'package:keystona/features/maintenance/screens/task_history_screen.dart';
import 'package:keystona/features/maintenance/screens/task_log_screen.dart';
import 'package:keystona/features/maintenance/services/task_dates.dart';
import '../../../support/responsive_harness.dart';

/// Today, date-only, so every date maths in a test is stable at any hour.
DateTime get today => TaskDates.dateOnly(DateTime.now());

DateTime daysFromToday(int days) => TaskDates.addDays(today, days);

MaintenanceTask fixtureTask({
  String id = 't1',
  String name = 'Replace HVAC air filter',
  String category = 'HVAC',
  DateTime? due,
  RecurrenceType recurrence = RecurrenceType.quarterly,
  TaskStatus status = TaskStatus.scheduled,
  String? description = 'A clogged filter makes the furnace work harder.',
  String? instructions =
      'Set the thermostat to **Off** so the blower stops.\n'
      '2. Slide the old filter out of the slot.\n'
      'Slide the new one in with the **arrow pointing toward the furnace**.',
  int? minutes = 15,
  List<String> supplies = const ['16 × 25 × 1 · MERV 8'],
  List<String> tools = const ['A marker'],
  String? skipReason,
  TaskOrigin origin = TaskOrigin.systemGenerated,
  String? season,
  double? estimatedCost,
  String? notes,
  int? intervalYears,
}) => MaintenanceTask(
  id: id,
  propertyId: 'p1',
  userId: 'u1',
  name: name,
  category: category,
  dueDate: due ?? daysFromToday(3),
  recurrence: recurrence,
  status: status,
  description: description,
  instructions: instructions,
  estimatedMinutes: minutes,
  suppliesNeeded: supplies,
  toolsNeeded: tools,
  skipReason: skipReason,
  taskOrigin: origin,
  season: season,
  estimatedCost: estimatedCost,
  notes: notes,
  recurrenceIntervalYears: intervalYears,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

TaskCompletion fixtureCompletion(
  String id,
  DateTime date, {
  String by = 'diy',
  double? labor,
  double? parts,
  int? minutes = 10,
  String? notes,
  String? company,
  List<String> findings = const [],
  DateTime? dueDate,
}) => TaskCompletion(
  id: id,
  taskId: 't1',
  userId: 'u1',
  propertyId: 'p1',
  completedDate: date,
  completedBy: by,
  contractorCompany: company,
  serviceCost: labor,
  materialsCost: parts,
  timeSpentMinutes: minutes,
  notes: notes,
  findings: findings,
  dueDate: dueDate,
  createdAt: date,
);

const TaskParent kFurnace = TaskParent(
  kind: TaskParentKind.system,
  id: 's1',
  name: 'Furnace',
  model: 'NF95-080B',
  location: 'Basement',
  health: TaskParentHealth.healthy,
);

/// Four quarterly completions, newest first, each one interval after the
/// last: Jul and Oct on time, Apr two days late.
List<TaskCompletion> fixtureCompletions() {
  final jan = daysFromToday(-300);
  final apr = TaskDates.addDays(
    TaskDates.next(RecurrenceType.quarterly, jan),
    2,
  );
  final jul = TaskDates.next(RecurrenceType.quarterly, apr);
  final oct = TaskDates.addDays(
    TaskDates.next(RecurrenceType.quarterly, jul),
    -3,
  );
  return [
    fixtureCompletion(
      'c4',
      oct,
      labor: 22,
      notes: 'MERV 8 from the hardware store.',
    ),
    fixtureCompletion('c3', jul, labor: 22),
    fixtureCompletion('c2', apr, labor: 22, minutes: 15),
    fixtureCompletion(
      'c1',
      jan,
      by: 'contractor',
      company: 'Summit Heating & Air',
    ),
  ];
}

TaskDetail fixtureDetail({
  MaintenanceTask? task,
  List<TaskCompletion>? completions,
  TaskParent? parent = kFurnace,
  int? reminderDays = 7,
  List<TaskSkip> skips = const [],
}) => TaskDetail(
  task: task ?? fixtureTask(),
  completions: completions ?? fixtureCompletions().take(3).toList(),
  parent: parent,
  reminderDaysBefore: reminderDays,
  skips: skips,
);

TaskSkip fixtureSkip(
  String id,
  DateTime skippedOn, {
  DateTime? due,
  String? reason,
}) => TaskSkip(
  id: id,
  taskId: 't1',
  skippedOn: skippedOn,
  dueDate: due ?? skippedOn,
  reason: reason,
);

/// An in-memory [TaskDetailRepository] that applies writes to its own copy
/// of the detail, so a refetch after a write shows the write.
class FakeTaskDetailRepository implements TaskDetailRepository {
  FakeTaskDetailRepository(
    this.detail, {
    this.photos = const {},
    this.failFetch = false,
    this.failInsert = false,
    this.fetchGate,
    this.insertGate,
  });

  TaskDetail detail;
  Map<String, List<CompletionPhoto>> photos;
  bool failFetch;
  bool failInsert;
  bool failDelete = false;
  bool failRestore = false;

  /// When set, [fetchDetail] waits for it (to hold the loading state).
  Completer<void>? fetchGate;

  /// When set, [insertCompletion] waits for it (to observe optimistic state).
  Completer<void>? insertGate;

  final List<TaskLogDraft> inserted = [];

  /// The occurrence each inserted completion answered (null: a past entry).
  final List<DateTime?> insertedDueDates = [];
  final List<({TaskStatus status, DateTime due})> schedules = [];
  final List<String> deletedCompletions = [];
  final List<String> deletedTasks = [];
  final List<String> restoredTasks = [];

  @override
  Future<TaskDetail> fetchDetail(String taskId) async {
    final gate = fetchGate;
    if (gate != null) await gate.future;
    if (failFetch) throw StateError('offline');
    return detail;
  }

  @override
  Future<Map<String, List<CompletionPhoto>>> completionPhotos(
    List<String> completionIds,
  ) async => photos;

  @override
  Future<String> insertCompletion({
    required MaintenanceTask task,
    required TaskLogDraft draft,
    DateTime? dueDate,
  }) async {
    final gate = insertGate;
    if (gate != null) await gate.future;
    if (failInsert) throw StateError('insert failed');
    inserted.add(draft);
    insertedDueDates.add(dueDate);
    final id = 'new-${inserted.length}';
    detail = detail.copyWith(
      completions: [
        fixtureCompletion(
          id,
          draft.completedDate,
          by: draft.doer.value,
          findings: [for (final f in draft.findings) f.value],
          dueDate: dueDate,
        ),
        ...detail.completions,
      ]..sort((a, b) => b.completedDate.compareTo(a.completedDate)),
    );
    return id;
  }

  @override
  Future<void> updateSchedule(
    String taskId, {
    required TaskStatus status,
    required DateTime dueDate,
  }) async {
    schedules.add((status: status, due: dueDate));
    detail = detail.copyWith(
      task: detail.task.copyWith(status: status, dueDate: dueDate),
    );
  }

  @override
  Future<void> deleteCompletion(String completionId) async {
    deletedCompletions.add(completionId);
    detail = detail.copyWith(
      completions: [
        for (final c in detail.completions)
          if (c.id != completionId) c,
      ],
    );
  }

  @override
  Future<void> deleteTask(String taskId) async {
    if (failDelete) throw StateError('delete failed');
    deletedTasks.add(taskId);
  }

  @override
  Future<void> restoreTask(String taskId) async {
    if (failRestore) throw StateError('restore failed');
    restoredTasks.add(taskId);
  }
}

/// Overrides that keep every task screen off Supabase.
List<Override> taskOverrides(
  FakeTaskDetailRepository repo, {
  List<TaskPro> pros = const [],
  List<ReceiptOption> receipts = const [],
}) => [
  taskDetailRepositoryProvider.overrideWithValue(repo),
  taskProsProvider.overrideWith((ref) async => pros),
  taskReceiptOptionsProvider.overrideWith((ref) async => receipts),
];

/// Phone-sized viewport for tests that are not about responsiveness.
void usePhone(WidgetTester tester, {Size size = const Size(390, 844)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Pumps [screen] inside a router so `context.push/pop` work. The router
/// starts on [start] and knows the pages in [routes].
Future<GoRouter> pumpRouted(
  WidgetTester tester, {
  required String start,
  required List<GoRoute> routes,
  required List<Override> overrides,
  double textScale = 1,
}) async {
  usePhone(tester);
  final router = GoRouter(initialLocation: start, routes: routes);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

/// The task routes, wired like the app: detail, its history, the Log screen
/// and stand-in pages for the places they link to.
List<GoRoute> taskRoutes() => [
  GoRoute(
    path: '/maintenance',
    builder: (_, _) => const Scaffold(body: Text('TASKS TAB')),
    routes: [
      GoRoute(
        path: 'edit/:taskId',
        builder: (_, _) => const Scaffold(body: Text('EDIT PAGE')),
      ),
      GoRoute(
        path: 'complete/:taskId',
        builder: (_, s) => TaskLogScreen(taskId: s.pathParameters['taskId']!),
      ),
      GoRoute(
        path: ':taskId',
        builder: (_, s) =>
            TaskDetailScreen(taskId: s.pathParameters['taskId']!),
        routes: [
          GoRoute(
            path: 'history',
            builder: (_, s) =>
                TaskHistoryScreen(taskId: s.pathParameters['taskId']!),
          ),
        ],
      ),
    ],
  ),
  GoRoute(
    path: '/home/systems/:systemId',
    builder: (_, _) => const Scaffold(body: Text('SYSTEM PAGE')),
  ),
];

/// Opens [location] inside the task routes with [repo] behind them.
Future<GoRouter> pumpTasks(
  WidgetTester tester,
  FakeTaskDetailRepository repo, {
  String location = '/maintenance/t1',
  List<TaskPro> pros = const [],
  List<ReceiptOption> receipts = const [],
  double textScale = 1,
}) => pumpRouted(
  tester,
  start: location,
  routes: taskRoutes(),
  overrides: taskOverrides(repo, pros: pros, receipts: receipts),
  textScale: textScale,
);

/// [testResponsive] that waits for the data to arrive before checking for
/// layout errors, and that [expectText] is on screen.
void testResponsiveLoaded(
  String description,
  Widget Function() build,
  FakeTaskDetailRepository Function() repo, {
  required String expectText,
  List<TaskPro> pros = const [],
}) {
  for (final viewport in activeViewports) {
    for (final scale in scalesFor(viewport)) {
      testWidgets('$description @ ${viewport.name}, text x$scale', (
        tester,
      ) async {
        await pumpScreen(
          tester,
          build,
          viewport: viewport,
          textScale: scale,
          wrap: (app) => ProviderScope(
            overrides: taskOverrides(repo(), pros: pros),
            child: app,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.textContaining(expectText), findsWidgets);
      });
    }
  }
}
