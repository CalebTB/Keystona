import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/maintenance_task.dart';
import '../models/quick_completion.dart';
import '../models/task_schedule.dart';
import '../models/task_undo.dart';
import '../services/reminder_switch.dart';
import 'home_health_score_provider.dart';
import 'maintenance_repository_provider.dart';
import 'task_detail_provider.dart';
import 'task_progress_provider.dart';

part 'maintenance_tasks_provider.g.dart';

/// The property's maintenance tasks, plus every change the Tasks tab makes to
/// them.
///
/// Changes are optimistic: the local list updates first and the write follows,
/// the state never goes to loading around a write. A change that can be taken
/// back returns a [TaskUndo]; pass it to [undo].
@riverpod
class MaintenanceTasksNotifier extends _$MaintenanceTasksNotifier {
  @override
  Future<List<MaintenanceTask>> build() =>
      ref.read(maintenanceTasksRepositoryProvider).fetchTasks();

  List<MaintenanceTask> get _tasks => state.value ?? const [];

  /// The task with [taskId], if loaded.
  MaintenanceTask? taskById(String taskId) =>
      _tasks.where((t) => t.id == taskId).firstOrNull;

  /// Refetches the list. Keeps showing the current list while it loads.
  Future<void> refresh() async {
    state = await AsyncValue.guard(
      ref.read(maintenanceTasksRepositoryProvider).fetchTasks,
    );
  }

  // ─── Local state ────────────────────────────────────────────────────────────

  void _replace(MaintenanceTask updated) {
    state = AsyncData([
      for (final t in _tasks) t.id == updated.id ? updated : t,
    ]);
  }

  /// [task] as it looks once done on [completedOn]: a recurring task rolls
  /// forward to its next date, a one-time task is completed.
  static MaintenanceTask rolledForward(
    MaintenanceTask task,
    DateTime completedOn,
  ) {
    if (task.recurrence == RecurrenceType.none) {
      return task.copyWith(status: TaskStatus.completed);
    }
    return task.copyWith(
      status: TaskStatus.scheduled,
      dueDate: TaskSchedule.nextDate(task, base: completedOn),
    );
  }

  // ─── Done ───────────────────────────────────────────────────────────────────

  /// Marks [taskId] done in the local list only, so the row reacts at once.
  /// Returns the task as it was, or null when it is not loaded. Nothing is
  /// written until [commitDone].
  MaintenanceTask? markDoneLocally(String taskId, {DateTime? on}) {
    final task = taskById(taskId);
    if (task == null) return null;
    _replace(rolledForward(task, on ?? TaskSchedule.dayOf(DateTime.now())));
    return task;
  }

  /// Puts [previous] back in the local list without writing anything.
  void revertLocally(MaintenanceTask previous) => _replace(previous);

  /// Writes the completion of [previous] (the task before [markDoneLocally])
  /// and schedules its next occurrence.
  Future<TaskUndo> commitDone(
    MaintenanceTask previous,
    QuickCompletion completion,
  ) async {
    _replace(rolledForward(previous, completion.completedOn));
    final repository = ref.read(maintenanceTasksRepositoryProvider);
    // The completion answers the occurrence the task was on before it rolled.
    final completionId = await repository.insertCompletion(
      previous,
      completion.withDueDate(previous.dueDate),
    );
    final rolled = rolledForward(previous, completion.completedOn);
    await repository.updateTask(previous.id, {
      'due_date': TaskSchedule.dateColumn(rolled.dueDate),
      'status': rolled.status.value,
    });
    _afterWrite();
    return TaskUndo(previous: previous, completionId: completionId);
  }

  // ─── Other actions ──────────────────────────────────────────────────────────

  /// Skips a task. A recurring task rolls forward; a one-time task is marked
  /// skipped. The skipped occurrence is logged in `task_skips` ([reason]
  /// says why, when known).
  Future<TaskUndo?> skipTask(String taskId, {String? reason}) async {
    final previous = taskById(taskId);
    if (previous == null) return null;
    final isRecurring = previous.recurrence != RecurrenceType.none;
    final next = isRecurring
        ? previous.copyWith(
            status: TaskStatus.scheduled,
            dueDate: TaskSchedule.nextDate(previous),
            skipReason: reason,
          )
        : previous.copyWith(status: TaskStatus.skipped, skipReason: reason);
    _replace(next);
    final repository = ref.read(maintenanceTasksRepositoryProvider);
    final skipId = await repository.insertSkip(
      previous,
      dueDate: previous.dueDate,
      skippedOn: TaskSchedule.dayOf(DateTime.now()),
      reason: reason,
    );
    try {
      await repository.updateTask(previous.id, _columns(next));
    } catch (_) {
      // Do not leave a skip in the history for a schedule that never moved.
      try {
        await repository.deleteSkip(skipId);
      } catch (_) {}
      rethrow;
    }
    _afterWrite();
    return TaskUndo(previous: previous, skipId: skipId);
  }

  /// Pushes a task's due date to [dueDate]; it stays on the list.
  Future<TaskUndo?> pushBack(String taskId, DateTime dueDate) async {
    final previous = taskById(taskId);
    if (previous == null) return null;
    return _apply(
      previous,
      previous.copyWith(status: TaskStatus.scheduled, dueDate: dueDate),
    );
  }

  /// Turns the reminder off. It is hidden everywhere and no longer counts
  /// toward Home Health. Records when, and [reason] when there is one.
  Future<TaskUndo?> stopReminders(String taskId, {String? reason}) async {
    final previous = taskById(taskId);
    if (previous == null) return null;
    final why = reason?.trim();
    return _apply(
      previous,
      previous.copyWith(
        notificationsEnabled: false,
        notificationsOffAt: DateTime.now().toUtc(),
        notificationsOffReason: why == null || why.isEmpty ? null : why,
      ),
    );
  }

  /// Changes how often a task repeats. The choices are plain recurrences, so
  /// any "every N years" interval is dropped (the database only allows one on
  /// an annual task).
  Future<TaskUndo?> changeFrequency(
    String taskId,
    RecurrenceType recurrence,
  ) async {
    final previous = taskById(taskId);
    if (previous == null) return null;
    return _apply(
      previous,
      previous.copyWith(recurrence: recurrence, recurrenceIntervalYears: null),
    );
  }

  Future<TaskUndo> _apply(
    MaintenanceTask previous,
    MaintenanceTask next,
  ) async {
    _replace(next);
    await ref
        .read(maintenanceTasksRepositoryProvider)
        .updateTask(previous.id, _columns(next));
    _afterWrite();
    return TaskUndo(previous: previous);
  }

  /// Takes an action back: removes its completion or skip (if any) and
  /// restores the task as it was.
  Future<void> undo(TaskUndo undo) async {
    _replace(undo.previous);
    final repository = ref.read(maintenanceTasksRepositoryProvider);
    if (undo.completionId != null) {
      await repository.deleteCompletion(undo.completionId!);
    }
    if (undo.skipId != null) await repository.deleteSkip(undo.skipId!);
    await repository.updateTask(undo.previous.id, _columns(undo.previous));
    _afterWrite();
    // The task's detail screen may be open behind the snackbar: refetch it so
    // it doesn't keep showing the action that was just taken back.
    ref.invalidate(taskDetailProvider(undo.previous.id));
  }

  /// The columns an action can change, written back as one update.
  static Map<String, dynamic> _columns(MaintenanceTask task) => {
    'due_date': TaskSchedule.dateColumn(task.dueDate),
    'status': task.status.value,
    'skip_reason': task.skipReason,
    ...ReminderSwitch.columns(
      enabled: task.notificationsEnabled,
      reason: task.notificationsOffReason,
      now: task.notificationsOffAt,
    ),
    'recurrence': task.recurrence.value,
    'recurrence_interval_years': task.recurrenceIntervalYears,
  };

  void _afterWrite() {
    ref.invalidate(taskProgressProvider);
    ref.invalidate(homeHealthScoreProvider);
  }

  // ─── Create and edit ────────────────────────────────────────────────────────

  /// Creates a new task. [fields] must include `name`, `category`, `due_date`,
  /// `task_origin`, `property_id` and `user_id`.
  Future<void> addTask(Map<String, dynamic> fields) async {
    await ref.read(maintenanceTasksRepositoryProvider).insertTask(fields);
    await refresh();
  }

  /// Updates the changed columns of an existing task.
  Future<void> updateTask(String taskId, Map<String, dynamic> fields) async {
    await ref
        .read(maintenanceTasksRepositoryProvider)
        .updateTask(taskId, fields);
    await refresh();
  }
}
