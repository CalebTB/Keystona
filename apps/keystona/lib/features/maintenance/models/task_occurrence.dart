import 'maintenance_task.dart';
import 'task_schedule.dart';

/// One date a task is due: its real due date, or a later repeat of it.
///
/// A recurring task is one row that rolls forward, so the year view projects
/// its repeats. Only the first occurrence ([projected] false) can be acted on.
class TaskOccurrence {
  const TaskOccurrence({
    required this.task,
    required this.date,
    this.projected = false,
  });

  final MaintenanceTask task;
  final DateTime date;

  /// A repeat that has not been scheduled yet.
  final bool projected;
}

/// Builds the occurrences of open tasks inside a window of months.
abstract final class TaskOccurrences {
  /// Weekly tasks would flood the year view, so only recurrences of a month
  /// or longer are projected.
  static bool _projects(RecurrenceType type) => switch (type) {
    RecurrenceType.none ||
    RecurrenceType.weekly ||
    RecurrenceType.biweekly => false,
    _ => true,
  };

  /// Occurrences of [tasks] that fall from [from] up to (not including) the
  /// first day of the month [months] after [from]'s month, soonest first.
  /// Overdue tasks are left out: they are listed on their own.
  static List<TaskOccurrence> inWindow(
    Iterable<MaintenanceTask> tasks, {
    required DateTime from,
    required int months,
  }) {
    final end = DateTime(from.year, from.month + months);
    final result = <TaskOccurrence>[];
    for (final task in tasks.where(TaskSchedule.isOpen)) {
      var date = TaskSchedule.dayOf(task.dueDate);
      if (date.isBefore(from)) continue;
      var projected = false;
      while (date.isBefore(end)) {
        result.add(
          TaskOccurrence(task: task, date: date, projected: projected),
        );
        if (!_projects(task.recurrence)) break;
        final next = TaskSchedule.nextDate(task, base: date);
        if (!next.isAfter(date)) break;
        date = next;
        projected = true;
      }
    }
    result.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      return byDate != 0 ? byDate : a.task.name.compareTo(b.task.name);
    });
    return result;
  }

  /// The occurrences in [list] that fall in the given [year] and [month].
  static List<TaskOccurrence> inMonth(
    List<TaskOccurrence> list,
    int year,
    int month,
  ) => list.where((o) => o.date.year == year && o.date.month == month).toList();
}
