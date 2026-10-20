import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/maintenance_task.dart';
import '../models/task_completion.dart';
import '../models/task_detail.dart';
import '../models/task_log_draft.dart';
import '../services/task_dates.dart';
import 'home_health_score_provider.dart';
import 'maintenance_tasks_provider.dart';
import 'reminders_providers.dart';
import 'task_repositories_provider.dart';

part 'task_detail_provider.g.dart';

/// Detail state for one maintenance task, keyed by id and auto-disposed when
/// its screens are popped. Fetches the task with its parent, reminder lead
/// time and completions in one query (no N+1).
///
/// Writes are optimistic: local state changes first (never `AsyncLoading`),
/// then the database, and a failed write puts the old state back and rethrows
/// so the screen can show the error.
@riverpod
class TaskDetailNotifier extends _$TaskDetailNotifier {
  @override
  Future<TaskDetail> build(String taskId) =>
      ref.watch(taskDetailRepositoryProvider).fetchDetail(taskId);

  /// Saves a log from the Log screen.
  ///
  /// The task's schedule rolls forward only when this is the newest
  /// completion; logging a past one adds history without moving the due date.
  /// Returns what is needed to undo it.
  Future<CompletionReceipt> logCompletion(TaskLogDraft draft) async {
    final detail = state.value ?? await future;
    final repo = ref.read(taskDetailRepositoryProvider);
    final task = detail.task;

    final newest =
        detail.completions.isEmpty ||
        !TaskDates.dateOnly(
          draft.completedDate,
        ).isBefore(TaskDates.dateOnly(detail.completions.first.completedDate));
    final recurring = task.recurrence != RecurrenceType.none;
    final nextDue = recurring
        ? TaskDates.next(
            task.recurrence,
            draft.completedDate,
            intervalYears: task.recurrenceIntervalYears,
          )
        : task.dueDate;
    final nextStatus = recurring ? TaskStatus.scheduled : TaskStatus.completed;

    // The occurrence this completion answers. A past entry (older than the
    // newest completion) answers none, so it has no due date.
    final answeredDue = newest ? task.dueDate : null;

    final now = DateTime.now();
    state = AsyncData(
      detail.copyWith(
        task: newest
            ? task.copyWith(status: nextStatus, dueDate: nextDue)
            : task,
        completions: [
          TaskCompletion(
            id: 'optimistic_${now.microsecondsSinceEpoch}',
            taskId: task.id,
            userId: task.userId,
            propertyId: task.propertyId,
            completedDate: draft.completedDate,
            completedBy: draft.doer.value,
            serviceCost: draft.laborCost > 0 ? draft.laborCost : null,
            materialsCost: draft.partsCost > 0 ? draft.partsCost : null,
            timeSpentMinutes: draft.minutes,
            notes: draft.notes,
            findings: [for (final f in draft.findings) f.value],
            logToItemHistory: draft.addToItemHistory,
            dueDate: answeredDue,
            createdAt: now,
          ),
          ...detail.completions,
        ]..sort((a, b) => b.completedDate.compareTo(a.completedDate)),
      ),
    );

    final String completionId;
    try {
      completionId = await repo.insertCompletion(
        task: task,
        draft: draft,
        dueDate: answeredDue,
      );
      if (newest) {
        await repo.updateSchedule(
          task.id,
          status: nextStatus,
          dueDate: nextDue,
        );
      }
    } catch (_) {
      state = AsyncData(detail);
      _invalidateSiblings();
      rethrow;
    }
    _invalidateSiblings();
    return CompletionReceipt(
      completionId: completionId,
      originalDueDate: newest ? task.dueDate : null,
    );
  }

  /// Takes a log back: deletes the completion and, when it had moved the
  /// schedule, puts the old due date (and the status it implies) back.
  Future<void> undoCompletion(CompletionReceipt receipt) async {
    final detail = state.value;
    final repo = ref.read(taskDetailRepositoryProvider);
    final original = receipt.originalDueDate;
    final today = TaskDates.dateOnly(DateTime.now());
    final restored = original == null
        ? null
        : original.isBefore(today)
        ? TaskStatus.overdue
        : TaskStatus.scheduled;

    if (detail != null) {
      state = AsyncData(
        detail.copyWith(
          task: original == null
              ? detail.task
              : detail.task.copyWith(status: restored!, dueDate: original),
          completions: [
            for (final c in detail.completions)
              if (c.id != receipt.completionId) c,
          ],
        ),
      );
    }

    try {
      await repo.deleteCompletion(receipt.completionId);
      if (original != null) {
        await repo.updateSchedule(taskId, status: restored!, dueDate: original);
      }
    } catch (_) {
      if (detail != null) state = AsyncData(detail);
      _invalidateSiblings();
      rethrow;
    }
    _invalidateSiblings();
  }

  /// Soft-deletes this task (`soft_delete_task`). The caller pops the screen
  /// afterwards and offers Undo through [TaskDeletion.restore].
  Future<void> deleteTask() async {
    await ref.read(taskDetailRepositoryProvider).deleteTask(taskId);
    ref.invalidate(maintenanceTasksProvider);
    ref.invalidate(homeHealthScoreProvider);
    ref.invalidate(remindersProvider);
  }

  /// Sibling providers read the same rows; invalidate them (safe even when
  /// they are disposed) and refetch this one from the database.
  void _invalidateSiblings() {
    ref.invalidate(maintenanceTasksProvider);
    ref.invalidate(homeHealthScoreProvider);
    ref.invalidateSelf();
  }
}
