import '../models/maintenance_task.dart';
import '../models/task_completion.dart';
import 'task_dates.dart';

/// How a completion compares with the day it was due.
enum TaskTimingKind { early, onTime, late, unknown }

/// A completion's timing: [days] early or late (always >= 0).
class TaskTiming {
  const TaskTiming(this.kind, [this.days = 0]);

  static const TaskTiming unknown = TaskTiming(TaskTimingKind.unknown);

  final TaskTimingKind kind;
  final int days;

  /// Early and on-time both count as "on time" in the history stats.
  bool get isOnTime =>
      kind == TaskTimingKind.early || kind == TaskTimingKind.onTime;

  bool get isKnown => kind != TaskTimingKind.unknown;

  /// Timing of finishing on [completed] when the task was due on [due].
  factory TaskTiming.between(DateTime due, DateTime completed) {
    final diff = TaskDates.daysBetween(due, completed);
    if (diff < 0) return TaskTiming(TaskTimingKind.early, -diff);
    if (diff == 0) return const TaskTiming(TaskTimingKind.onTime);
    return TaskTiming(TaskTimingKind.late, diff);
  }
}

/// Works out how each completion compared with the day it was due.
///
/// A completion carries the due date it answered (`due_date`), and that is
/// used whenever it is there. Older rows have none; for those, in a recurring
/// task, the date it was due is its predecessor's completion date plus one
/// interval. The oldest such completion (and every old completion of a
/// one-off task) has no known due date.
abstract final class TaskTimings {
  /// Timing by completion id for [completions] in any order. [intervalYears]
  /// is the task's "every N years", used by the derived fallback only.
  static Map<String, TaskTiming> derive(
    RecurrenceType recurrence,
    List<TaskCompletion> completions, {
    int? intervalYears,
  }) {
    final oldestFirst = [...completions]
      ..sort((a, b) => a.completedDate.compareTo(b.completedDate));
    final result = <String, TaskTiming>{};
    for (var i = 0; i < oldestFirst.length; i++) {
      final c = oldestFirst[i];
      final stored = c.dueDate;
      if (stored != null) {
        result[c.id] = TaskTiming.between(stored, c.completedDate);
      } else if (i == 0 || recurrence == RecurrenceType.none) {
        result[c.id] = TaskTiming.unknown;
      } else {
        final due = TaskDates.next(
          recurrence,
          oldestFirst[i - 1].completedDate,
          intervalYears: intervalYears,
        );
        result[c.id] = TaskTiming.between(due, c.completedDate);
      }
    }
    return result;
  }
}
