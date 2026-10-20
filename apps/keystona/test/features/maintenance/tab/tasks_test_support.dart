import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keystona/core/router/app_router.dart';
import 'package:keystona/features/maintenance/models/maintenance_task.dart';
import 'package:keystona/features/maintenance/models/quick_completion.dart';
import 'package:keystona/features/maintenance/models/task_progress.dart';
import 'package:keystona/features/maintenance/providers/maintenance_repository_provider.dart';
import 'package:keystona/features/maintenance/providers/tasks_today_provider.dart';
import 'package:keystona/features/maintenance/repositories/maintenance_tasks_repository.dart';

import '../../../support/responsive_harness.dart';

/// A Sunday, the day the kit's Tasks screens are drawn on.
final DateTime kToday = DateTime(2026, 10, 4);

DateTime day(int month, int dayOfMonth, [int year = 2026]) =>
    DateTime(year, month, dayOfMonth);

MaintenanceTask task(
  String id,
  String name, {
  required DateTime due,
  String category = 'HVAC',
  int? minutes,
  RecurrenceType recurrence = RecurrenceType.none,
  DiyOrPro who = DiyOrPro.diy,
  String? description,
  String? system,
  TaskStatus status = TaskStatus.scheduled,
  bool enabled = true,
  int? intervalYears,
}) => MaintenanceTask(
  id: id,
  propertyId: 'p1',
  userId: 'u1',
  name: name,
  category: category,
  dueDate: due,
  recurrence: recurrence,
  diyOrPro: who,
  description: description,
  estimatedMinutes: minutes,
  linkedSystemName: system,
  status: status,
  notificationsEnabled: enabled,
  recurrenceIntervalYears: intervalYears,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

/// The kit's October: one overdue task, one due today and a spread after it.
List<MaintenanceTask> kitTasks() => [
  task(
    'gutters',
    'Clean gutters & downspouts',
    due: day(9, 28),
    category: 'Exterior',
    minutes: 45,
    who: DiyOrPro.either,
    recurrence: RecurrenceType.biannual,
    description: "Clears fallen leaves before winter so water can't back up.",
  ),
  task(
    'smoke',
    'Test smoke & CO detectors',
    due: day(10, 4),
    category: 'Safety',
    minutes: 10,
  ),
  task(
    'hvac',
    'Replace HVAC air filter',
    due: day(10, 7),
    minutes: 15,
    recurrence: RecurrenceType.quarterly,
  ),
  task(
    'flush',
    'Flush water heater sediment',
    due: day(10, 13),
    category: 'Plumbing',
    minutes: 45,
  ),
  task(
    'roof',
    'Inspect roof flashing',
    due: day(10, 25),
    category: 'Roof',
    minutes: 60,
    who: DiyOrPro.professional,
  ),
  task(
    'faucets',
    'Shut off & drain outdoor faucets',
    due: day(11, 2),
    category: 'Plumbing',
    recurrence: RecurrenceType.annual,
  ),
];

/// In-memory tasks: nothing reaches Supabase.
class FakeMaintenanceTasksRepository implements MaintenanceTasksRepository {
  FakeMaintenanceTasksRepository(
    this.tasks, {
    this.progress = const TaskProgress(doneThisMonth: 6, doneThisWeek: 4),
    this.gate,
  });

  List<MaintenanceTask> tasks;
  TaskProgress progress;
  Completer<void>? gate;
  Object? failWith;
  Object? failWrites;

  /// Fails [updateTask] only (inserts still work).
  bool failUpdates = false;
  int loads = 0;
  final List<String> calls = [];
  final List<Map<String, dynamic>> updates = [];
  final List<QuickCompletion> completions = [];

  /// Every skip written, and the ones taken back.
  final List<({String id, String taskId, DateTime due, String? reason})> skips =
      [];
  final List<String> deletedSkips = [];

  @override
  Future<List<MaintenanceTask>> fetchTasks() async {
    loads++;
    if (gate != null) await gate!.future;
    if (failWith != null) throw failWith!;
    return [...tasks];
  }

  @override
  Future<TaskProgress> fetchProgress(DateTime today) async => progress;

  @override
  Future<String> insertCompletion(
    MaintenanceTask task,
    QuickCompletion completion,
  ) async {
    if (failWrites != null) throw failWrites!;
    completions.add(completion);
    calls.add('complete:${task.id}');
    return 'c${completions.length}';
  }

  @override
  Future<void> deleteCompletion(String completionId) async {
    calls.add('delete:$completionId');
  }

  @override
  Future<String> insertSkip(
    MaintenanceTask task, {
    required DateTime dueDate,
    required DateTime skippedOn,
    String? reason,
  }) async {
    if (failWrites != null) throw failWrites!;
    final id = 's${skips.length + 1}';
    skips.add((id: id, taskId: task.id, due: dueDate, reason: reason));
    calls.add('skip:${task.id}');
    return id;
  }

  @override
  Future<void> deleteSkip(String skipId) async {
    deletedSkips.add(skipId);
    calls.add('unskip:$skipId');
  }

  @override
  Future<void> updateTask(String taskId, Map<String, dynamic> fields) async {
    if (failWrites != null) throw failWrites!;
    if (failUpdates) throw StateError('update failed');
    calls.add('update:$taskId');
    updates.add({'id': taskId, ...fields});
  }

  @override
  Future<void> insertTask(Map<String, dynamic> fields) async {
    calls.add('insert');
  }
}

List<Override> tasksOverrides(
  FakeMaintenanceTasksRepository repository, {
  DateTime? today,
}) => [
  maintenanceTasksRepositoryProvider.overrideWithValue(repository),
  tasksTodayProvider.overrideWithValue(today ?? kToday),
];

/// Routes the screen under test at `/` and records where it navigates.
class RoutedApp extends StatelessWidget {
  RoutedApp({
    super.key,
    required Widget home,
    List<Override> overrides = const [],
    List<String>? visited,
  }) : _overrides = overrides,
       _router = GoRouter(
         routes: [
           GoRoute(path: '/', builder: (_, _) => home),
           for (final path in [
             AppRoutes.maintenanceCreate,
             AppRoutes.maintenanceAll,
             AppRoutes.maintenanceCompleteTask,
             AppRoutes.maintenanceTaskDetail,
           ])
             GoRoute(
               path: path,
               builder: (context, state) {
                 visited?.add(state.uri.path);
                 return Scaffold(body: Text('route ${state.uri.path}'));
               },
             ),
         ],
       );

  final List<Override> _overrides;
  final GoRouter _router;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: _overrides,
    child: MaterialApp.router(routerConfig: _router),
  );
}

/// A tall surface so a whole screen is on screen without scrolling.
void tallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// A phone-sized surface, so positions can be checked against a phone layout.
void phoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Lets routes, sheets and async loads finish. The pulse and shimmer
/// animations repeat forever, so `pumpAndSettle` would never return.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  // Small screens and large text push things below the fold.
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await settle(tester);
}

/// Pumps [screen] at every viewport and text scale with a fresh fake
/// repository, lets data load, runs [act] (open a sheet or menu) and fails on
/// any layout exception.
void testResponsiveFlow(
  String description,
  Widget Function() screen, {
  FakeMaintenanceTasksRepository Function()? repository,
  List<MaintenanceTask> Function()? tasks,
  Future<void> Function(WidgetTester tester)? act,
}) {
  for (final viewport in activeViewports) {
    for (final scale in scalesFor(viewport)) {
      testWidgets('$description @ ${viewport.name}, text x$scale', (
        tester,
      ) async {
        final repo =
            repository?.call() ??
            FakeMaintenanceTasksRepository(tasks?.call() ?? kitTasks());
        await pumpScreen(
          tester,
          screen,
          viewport: viewport,
          textScale: scale,
          wrap: (app) =>
              ProviderScope(overrides: tasksOverrides(repo), child: app),
        );
        await settle(tester);
        if (act != null) await act(tester);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
