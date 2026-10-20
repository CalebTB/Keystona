import 'maintenance_task.dart';
import 'task_occurrence.dart';
import 'task_schedule.dart';
import '../tasks_copy.dart';
import '../../../core/theme/aurora_tasks_a.dart';

/// One month of the year view.
class TaskMonth {
  const TaskMonth({required this.month, required this.occurrences});

  /// First day of the month.
  final DateTime month;
  final List<TaskOccurrence> occurrences;

  int get count => occurrences.length;

  /// Tasks that need a professional.
  int get pros =>
      occurrences.where((o) => o.task.diyOrPro == DiyOrPro.professional).length;
}

/// Everything All tasks shows: the overdue list and the next 12 months.
class TasksYearData {
  TasksYearData._({
    required this.overdue,
    required this.months,
    required this.openCount,
    required this.first,
  });

  /// Builds the year view for [today]. A non-empty [query] keeps only tasks
  /// whose name, area or system contains it.
  factory TasksYearData.from(
    List<MaintenanceTask> all, {
    required DateTime today,
    String query = '',
  }) {
    final needle = query.trim().toLowerCase();
    bool matches(MaintenanceTask t) =>
        needle.isEmpty ||
        t.name.toLowerCase().contains(needle) ||
        t.category.toLowerCase().contains(needle) ||
        (t.linkedSystemName ?? '').toLowerCase().contains(needle);

    final overdue =
        all
            .where((t) => TaskSchedule.isOverdue(t, today) && matches(t))
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final first = DateTime(today.year, today.month);
    final occurrences = TaskOccurrences.inWindow(
      all.where(matches),
      from: today,
      months: AuroraTasksA.monthsShown,
    );
    final months = [
      for (var i = 0; i < AuroraTasksA.monthsShown; i++)
        () {
          final month = DateTime(first.year, first.month + i);
          return TaskMonth(
            month: month,
            occurrences: TaskOccurrences.inMonth(
              occurrences,
              month.year,
              month.month,
            ),
          );
        }(),
    ];
    return TasksYearData._(
      overdue: overdue,
      months: months,
      openCount: overdue.length + occurrences.length,
      first: first,
    );
  }

  /// Overdue tasks, most overdue first.
  final List<MaintenanceTask> overdue;

  /// Twelve months starting with the current one.
  final List<TaskMonth> months;

  /// Overdue tasks plus every occurrence in the window.
  final int openCount;

  /// First day of the current month.
  final DateTime first;

  /// Tallest month, for scaling the bars.
  int get maxCount => months.fold(0, (max, m) => m.count > max ? m.count : max);

  /// "OCT 2026 – SEP 2027".
  String get range => TasksCopy.yearRange(first);
}
