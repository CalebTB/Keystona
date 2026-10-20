import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keystona/core/router/app_router.dart';
import 'package:keystona/features/maintenance/models/maintenance_task.dart';
import 'package:keystona/features/maintenance/models/reminder_item.dart';
import 'package:keystona/features/maintenance/models/suggested_task.dart';
import 'package:keystona/features/maintenance/models/task_draft.dart';
import 'package:keystona/features/maintenance/models/task_link_option.dart';
import 'package:keystona/features/maintenance/providers/reminders_providers.dart';
import 'package:keystona/features/maintenance/providers/task_form_providers.dart';
import 'package:keystona/features/maintenance/repositories/generated_tasks_repository.dart';
import 'package:keystona/features/maintenance/repositories/reminders_repository.dart';
import 'package:keystona/features/maintenance/repositories/task_form_repository.dart';

import '../../../support/responsive_harness.dart';

/// Sunday, the day the kit's Add a task storyboard is drawn on.
final DateTime kToday = DateTime(2026, 10, 4);

// ─── Add a task fixtures ──────────────────────────────────────────────────────

const List<TaskLinkOption> kLinkOptions = [
  TaskLinkOption(
    id: 's-furnace',
    kind: TaskLinkKind.system,
    name: 'Furnace',
    category: 'hvac',
    categoryLabel: 'HVAC',
    location: 'Basement',
    taskCount: 3,
  ),
  TaskLinkOption(
    id: 's-wh',
    kind: TaskLinkKind.system,
    name: 'Water heater',
    category: 'plumbing',
    categoryLabel: 'Plumbing',
    location: 'Basement',
    taskCount: 2,
  ),
  TaskLinkOption(
    id: 's-gutters',
    kind: TaskLinkKind.system,
    name: 'Gutters',
    category: 'roofing',
    categoryLabel: 'Roofing',
    taskCount: 1,
  ),
  TaskLinkOption(
    id: 'a-dryer',
    kind: TaskLinkKind.appliance,
    name: 'Dryer',
    category: 'appliance',
    categoryLabel: 'Laundry',
    taskCount: 1,
  ),
];

MaintenanceTask savedTask({
  String id = 't-1',
  String name = 'Replace HVAC air filter',
  String category = 'hvac',
  RecurrenceType recurrence = RecurrenceType.quarterly,
  String? systemId = 's-furnace',
  String? applianceId,
  String? notes = 'Behind the grille',
  double? estimatedCost,
  int? intervalYears,
}) => MaintenanceTask(
  id: id,
  propertyId: 'p1',
  userId: 'u1',
  name: name,
  category: category,
  dueDate: DateTime(2026, 11, 1),
  recurrence: recurrence,
  description: 'A clogged filter makes the furnace work harder.',
  notes: notes,
  estimatedCost: estimatedCost,
  recurrenceIntervalYears: intervalYears,
  estimatedMinutes: 30,
  linkedSystemId: systemId,
  linkedApplianceId: applianceId,
  suppliesNeeded: const ['16×25×1 filter', 'MERV 8'],
  createdAt: DateTime(2026, 8, 2),
  updatedAt: DateTime(2026, 8, 2),
);

class SavedCreate {
  SavedCreate(this.draft, this.propertyId, this.today);

  final TaskDraft draft;
  final String propertyId;
  final DateTime today;
}

class SavedUpdate {
  SavedUpdate(this.id, this.draft, this.category);

  final String id;
  final TaskDraft draft;
  final String category;
}

class FakeTaskFormRepository implements TaskFormRepository {
  FakeTaskFormRepository({
    this.propertyId = 'p1',
    this.options = kLinkOptions,
    this.task,
    this.contextFails = false,
    this.gate,
  });

  final String? propertyId;
  final List<TaskLinkOption> options;
  final MaintenanceTask? task;
  bool contextFails;
  final Completer<void>? gate;

  Object? saveError;
  final List<SavedCreate> created = [];
  final List<SavedUpdate> updated = [];
  int contextLoads = 0;

  @override
  Future<TaskFormContext> loadContext() async {
    contextLoads++;
    if (gate != null) await gate!.future;
    if (contextFails) throw StateError('offline');
    return TaskFormContext(propertyId: propertyId, options: options);
  }

  @override
  Future<MaintenanceTask?> loadTask(String taskId) async => task;

  @override
  Future<void> create(
    TaskDraft draft, {
    required String propertyId,
    required DateTime today,
  }) async {
    final e = saveError;
    if (e != null) throw e;
    created.add(SavedCreate(draft, propertyId, today));
  }

  @override
  Future<void> update(
    String taskId,
    TaskDraft draft, {
    required String category,
    required DateTime today,
  }) async {
    final e = saveError;
    if (e != null) throw e;
    updated.add(SavedUpdate(taskId, draft, category));
  }
}

// ─── Reminder fixtures ────────────────────────────────────────────────────────

ReminderItem reminder(
  String id,
  String name, {
  String category = 'hvac',
  RecurrenceType recurrence = RecurrenceType.annual,
  TaskOrigin origin = TaskOrigin.systemGenerated,
  bool enabled = true,
  String? systemId,
  String? applianceId,
  String? itemName,
  DateTime? updatedAt,
  DateTime? offAt,
  String? offReason,
  List<String> tags = const [],
  int? intervalYears,
}) => ReminderItem(
  id: id,
  name: name,
  category: category,
  recurrence: recurrence,
  origin: origin,
  enabled: enabled,
  createdAt: DateTime(2026, 8, 2),
  updatedAt: updatedAt ?? DateTime(2026, 9, 12),
  offAt: offAt,
  offReason: offReason,
  tags: tags,
  intervalYears: intervalYears,
  systemId: systemId,
  applianceId: applianceId,
  itemName: itemName,
);

RemindersData kReminders() => RemindersData(
  addressLine: '1428 Elm Hollow Ln',
  climateZone: 4,
  items: [
    reminder(
      'f1',
      'Replace HVAC air filter',
      recurrence: RecurrenceType.quarterly,
      systemId: 's-furnace',
      itemName: 'Furnace',
    ),
    reminder(
      'f2',
      'Service the furnace',
      systemId: 's-furnace',
      itemName: 'Furnace',
    ),
    reminder(
      'f3',
      'Replace the humidifier pad',
      enabled: false,
      systemId: 's-furnace',
      itemName: 'Furnace',
    ),
    reminder(
      'w1',
      'Clean the drain pump filter',
      category: 'laundry',
      enabled: false,
      applianceId: 'a-washer',
      itemName: 'Washer',
      updatedAt: DateTime(2026, 9, 24),
    ),
    reminder(
      'h1',
      'Test smoke & CO detectors',
      category: 'safety',
      recurrence: RecurrenceType.monthly,
    ),
    reminder(
      'h2',
      'Clean gutters & downspouts',
      category: 'exterior',
      recurrence: RecurrenceType.biannual,
    ),
    reminder(
      'h3',
      'Power-wash the siding',
      category: 'exterior',
      enabled: false,
      updatedAt: DateTime(2026, 8, 30),
    ),
    reminder(
      'h4',
      'Shut off and drain the sprinklers',
      category: 'landscaping',
      enabled: false,
      updatedAt: DateTime(2026, 9, 2),
    ),
    reminder(
      'h5',
      'Drain the outdoor faucets',
      category: 'seasonal',
      origin: TaskOrigin.climateTriggered,
    ),
    reminder(
      'm1',
      'Clean the window wells',
      category: 'other',
      origin: TaskOrigin.custom,
      recurrence: RecurrenceType.annual,
    ),
  ],
);

class FakeRemindersRepository implements RemindersRepository {
  FakeRemindersRepository(this.data, {this.fetchFailures = 0, this.gate});

  RemindersData data;

  /// Holds the first fetch until completed (to see the loading state).
  final Completer<void>? gate;

  /// Fetches that fail before one succeeds.
  int fetchFailures;
  Object? writeError;

  final List<(String, bool)> enabledCalls = [];

  /// The reason each [setEnabled] call carried, in call order.
  final List<String?> enabledReasons = [];

  /// The `offAt` each [setEnabled] call carried (Undo puts an old one back).
  final List<DateTime?> enabledOffAts = [];
  final List<(List<String>, bool)> manyCalls = [];
  final List<(String, RecurrenceType)> recurrenceCalls = [];
  final List<String> deleted = [];
  int fetches = 0;

  @override
  Future<RemindersData> fetch() async {
    fetches++;
    if (gate != null) await gate!.future;
    if (fetchFailures > 0) {
      fetchFailures--;
      throw StateError('offline');
    }
    return data;
  }

  void _maybeFail() {
    final e = writeError;
    if (e != null) throw e;
  }

  @override
  Future<void> setEnabled(
    String id, {
    required bool enabled,
    String? reason,
    DateTime? offAt,
  }) async {
    _maybeFail();
    enabledCalls.add((id, enabled));
    enabledReasons.add(reason);
    enabledOffAts.add(offAt);
  }

  @override
  Future<void> setManyEnabled(
    List<String> ids, {
    required bool enabled,
    String? reason,
  }) async {
    _maybeFail();
    manyCalls.add((ids, enabled));
  }

  @override
  Future<void> setRecurrence(String id, RecurrenceType recurrence) async {
    _maybeFail();
    recurrenceCalls.add((id, recurrence));
  }

  @override
  Future<void> delete(String id) async {
    _maybeFail();
    deleted.add(id);
  }
}

class FakeGeneratedTasksRepository implements GeneratedTasksRepository {
  Object? error;
  final List<List<SuggestedTask>> added = [];
  String? system;
  String? appliance;
  String? property;

  @override
  Future<void> addAll({
    required List<SuggestedTask> tasks,
    required String propertyId,
    String? linkedSystemId,
    String? linkedApplianceId,
  }) async {
    final e = error;
    if (e != null) throw e;
    added.add(tasks);
    property = propertyId;
    system = linkedSystemId;
    appliance = linkedApplianceId;
  }
}

const List<SuggestedTask> kSuggested = [
  SuggestedTask(
    name: 'Replace HVAC air filter',
    description: 'Every few months',
    category: 'hvac',
    recurrence: 'quarterly',
    priority: 'medium',
    diyOrPro: 'diy',
    estimatedMinutes: 15,
  ),
  SuggestedTask(
    name: 'Service the furnace',
    description: 'Before winter',
    category: 'hvac',
    recurrence: 'annual',
    priority: 'high',
    diyOrPro: 'professional',
    estimatedMinutes: 60,
  ),
  SuggestedTask(
    name: 'Check the flue pipe for rust',
    description: 'Look for rust',
    category: 'hvac',
    recurrence: 'annual',
    priority: 'medium',
    diyOrPro: 'diy',
    estimatedMinutes: 20,
  ),
];

// ─── Pumping ──────────────────────────────────────────────────────────────────

List<Override> reminderOverrides(FakeRemindersRepository repo) => [
  remindersRepositoryProvider.overrideWithValue(repo),
];

List<Override> formOverrides(FakeTaskFormRepository repo) => [
  taskFormRepositoryProvider.overrideWithValue(repo),
];

/// Lets futures and short animations finish. `pumpAndSettle` would wait
/// forever on a loading skeleton's shimmer.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Scrolls [finder] into view and lets the scroll land.
Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
}

/// Scrolls [finder] into view, then taps it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await settle(tester);
}

/// A route a screen can push to; shows where it went.
class _Landing extends StatelessWidget {
  const _Landing(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Scaffold(body: Text(label));
}

/// Pumps [screen] on top of a "start" page inside a router, so `pop`,
/// `push` and `go` all work, and returns the router.
Future<GoRouter> pumpRouted(
  WidgetTester tester,
  Widget screen, {
  List<Override> overrides = const [],
  Size size = const Size(390, 844),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(path: '/start', builder: (_, _) => const _Landing('start')),
      GoRoute(path: '/screen', builder: (_, _) => screen),
      for (final path in [
        AppRoutes.maintenanceCreate,
        AppRoutes.maintenanceEditTask,
        AppRoutes.homeSystemDetail,
        AppRoutes.homeApplianceDetail,
        AppRoutes.homeReminders,
        AppRoutes.home,
        AppRoutes.settings,
      ])
        GoRoute(path: path, builder: (_, state) => _Landing('at ${state.uri}')),
    ],
  );
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
  router.push('/screen');
  await settle(tester);
  return router;
}

/// One test per viewport x text scale. Unlike `testResponsive` it lets the
/// screen's data load first, and runs [after] (taps that open more UI).
void testResponsiveLoaded(
  String description,
  Widget Function() build, {
  required List<Override> Function() overrides,
  Future<void> Function(WidgetTester tester)? after,
}) {
  for (final viewport in activeViewports) {
    for (final scale in scalesFor(viewport)) {
      testWidgets('$description @ ${viewport.name}, text x$scale', (
        tester,
      ) async {
        await pumpRouted(
          tester,
          build(),
          overrides: overrides(),
          size: viewport.size,
          textScale: scale,
        );
        if (after != null) await after(tester);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
