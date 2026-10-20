import '../models/maintenance_task.dart';
import '../models/task_detail.dart';
import 'task_dates.dart';
import 'task_due.dart';
import 'task_format.dart';
import 'task_timing.dart';

/// Where a task is in its life on the detail screen.
enum TaskPhase { open, done, skipped }

/// Everything the detail screen derives from a [TaskDetail], worked out once
/// (pure Dart, no Flutter) so `build()` only lays it out.
class TaskDetailView {
  TaskDetailView._({
    required this.phase,
    required this.due,
    required this.doneTitle,
    required this.nextLine,
    required this.canUndo,
    required this.doneToday,
    required this.timings,
    required this.onTime,
    required this.known,
    required this.nextAfterThis,
  });

  /// [today] is date-only. [dueBeforeDone] is the due date this task had
  /// before it was marked done in this session, which is what makes "3 days
  /// early" and Undo possible right after.
  factory TaskDetailView.of(
    TaskDetail detail, {
    required DateTime today,
    DateTime? dueBeforeDone,
  }) {
    final task = detail.task;
    final latest = detail.completions.isEmpty ? null : detail.completions.first;
    final doneToday =
        latest != null && TaskDates.dateOnly(latest.completedDate) == today;
    final phase = doneToday || task.status == TaskStatus.completed
        ? TaskPhase.done
        : task.status == TaskStatus.skipped
        ? TaskPhase.skipped
        : TaskPhase.open;

    final timings = TaskTimings.derive(
      task.recurrence,
      detail.completions,
      intervalYears: task.recurrenceIntervalYears,
    );
    var onTime = 0;
    var known = 0;
    for (final t in timings.values) {
      if (!t.isKnown) continue;
      known++;
      if (t.isOnTime) onTime++;
    }

    final recurring = task.recurrence != RecurrenceType.none;
    String? doneTitle;
    if (phase == TaskPhase.done) {
      final timing = (doneToday && dueBeforeDone != null)
          ? TaskTiming.between(dueBeforeDone, today)
          : (latest == null ? TaskTiming.unknown : timings[latest.id]);
      doneTitle = _doneTitle(
        doneOn: latest?.completedDate ?? today,
        today: today,
        timing: timing ?? TaskTiming.unknown,
      );
    }

    return TaskDetailView._(
      phase: phase,
      due: phase == TaskPhase.open ? TaskDue.of(task, today) : null,
      doneTitle: doneTitle,
      nextLine: phase == TaskPhase.done && recurring
          ? 'Next one is due ${TaskFormat.dateShort(task.dueDate)}'
          : null,
      canUndo: phase == TaskPhase.done && doneToday && dueBeforeDone != null,
      doneToday: doneToday,
      timings: timings,
      onTime: onTime,
      known: known,
      nextAfterThis: !recurring
          ? null
          : phase == TaskPhase.open
          ? TaskDates.next(
              task.recurrence,
              task.dueDate,
              intervalYears: task.recurrenceIntervalYears,
            )
          : task.dueDate,
    );
  }

  static String _doneTitle({
    required DateTime doneOn,
    required DateTime today,
    required TaskTiming timing,
  }) {
    final when = TaskDates.dateOnly(doneOn) == today
        ? 'Done today'
        : 'Done ${TaskFormat.dateShort(doneOn)}';
    return switch (timing.kind) {
      TaskTimingKind.early =>
        '$when, ${TaskFormat.timingWords(timing.days, late: false)}',
      TaskTimingKind.late =>
        '$when, ${TaskFormat.timingWords(timing.days, late: true)}',
      TaskTimingKind.onTime || TaskTimingKind.unknown => when,
    };
  }

  final TaskPhase phase;

  /// Urgency of an open task.
  final TaskDue? due;

  /// "Done today, 3 days early".
  final String? doneTitle;

  /// "Next one is due Jan 4, 2027".
  final String? nextLine;

  /// The done card can offer Undo (it was done in this session).
  final bool canUndo;

  /// The newest completion is from today.
  final bool doneToday;

  /// Timing by completion id.
  final Map<String, TaskTiming> timings;

  /// Completions on or before their due date, among [known] with a due date.
  final int onTime;
  final int known;

  /// The "Next after this" date; null for a one-time task.
  final DateTime? nextAfterThis;
}
