import '../tasks_copy.dart';
import 'maintenance_task.dart';
import 'task_occurrence.dart';
import 'task_progress.dart';
import 'task_schedule.dart';

/// How the upcoming list is grouped.
enum TaskGrouping { date, area }

/// One titled card of rows on the Tasks tab.
class TaskGroup {
  const TaskGroup({required this.title, required this.tasks});

  /// "THIS WEEK · 1".
  final String title;
  final List<MaintenanceTask> tasks;
}

/// Everything the Tasks tab and All tasks show, worked out once from the task
/// list. Pure Dart so it is easy to test.
class TasksTabData {
  TasksTabData._({
    required this.hero,
    required this.moreOverdue,
    required this.groups,
    required this.nextUp,
    required this.matches,
    required this.dueTodayCount,
    required this.openCount,
    required this.monthDone,
    required this.monthTotal,
    required this.weekDone,
    required this.daysUntilNext,
    required this.today,
    required this.hasQuery,
  });

  /// Builds the data for [today] from every task in the property.
  factory TasksTabData.from(
    List<MaintenanceTask> all, {
    required DateTime today,
    TaskProgress progress = TaskProgress.none,
    TaskGrouping grouping = TaskGrouping.date,
    String query = '',
  }) {
    final open = all.where(TaskSchedule.isOpen).toList()
      ..sort((a, b) {
        final byDate = a.dueDate.compareTo(b.dueDate);
        return byDate != 0
            ? byDate
            : b.priority.sortOrder.compareTo(a.priority.sortOrder);
      });
    final overdue = open
        .where((t) => TaskSchedule.isOverdue(t, today))
        .toList();
    final upcoming = open
        .where((t) => !TaskSchedule.isOverdue(t, today))
        .toList();
    final dueToday = upcoming
        .where((t) => TaskSchedule.daysUntil(t, today) == 0)
        .toList();

    final weekEnd = DateTime(today.year, today.month, today.day + 6);
    bool inMonth(MaintenanceTask t) {
      final d = TaskSchedule.dayOf(t.dueDate);
      return d.year == today.year && d.month == today.month;
    }

    final shown = upcoming
        .where(
          (t) => inMonth(t) || !TaskSchedule.dayOf(t.dueDate).isAfter(weekEnd),
        )
        .toList();

    final yearCount = TaskOccurrences.inWindow(
      all,
      from: today,
      months: 12,
    ).length;

    final needle = query.trim().toLowerCase();
    bool matches(MaintenanceTask t) =>
        t.name.toLowerCase().contains(needle) ||
        t.category.toLowerCase().contains(needle) ||
        (t.linkedSystemName ?? '').toLowerCase().contains(needle);

    return TasksTabData._(
      hero: overdue.isEmpty ? null : overdue.first,
      moreOverdue: overdue.skip(1).toList(),
      groups: switch (grouping) {
        TaskGrouping.date => _byDate(shown, today, weekEnd),
        TaskGrouping.area => _byArea(shown),
      },
      nextUp: upcoming.take(3).toList(),
      matches: needle.isEmpty ? const [] : open.where(matches).toList(),
      dueTodayCount: dueToday.length,
      openCount: overdue.length + yearCount,
      monthDone: progress.doneThisMonth,
      monthTotal:
          progress.doneThisMonth +
          overdue.length +
          upcoming.where(inMonth).length,
      weekDone: progress.doneThisWeek,
      daysUntilNext: upcoming.isEmpty
          ? null
          : TaskSchedule.daysUntil(upcoming.first, today),
      today: today,
      hasQuery: needle.isNotEmpty,
    );
  }

  static List<TaskGroup> _byDate(
    List<MaintenanceTask> shown,
    DateTime today,
    DateTime weekEnd,
  ) {
    final now = <MaintenanceTask>[];
    final week = <MaintenanceTask>[];
    final later = <MaintenanceTask>[];
    for (final t in shown) {
      final d = TaskSchedule.dayOf(t.dueDate);
      if (d == today) {
        now.add(t);
      } else if (!d.isAfter(weekEnd)) {
        week.add(t);
      } else {
        later.add(t);
      }
    }
    return [
      if (now.isNotEmpty)
        TaskGroup(
          title: TasksCopy.groupTitle(TasksCopy.groupToday, now.length),
          tasks: now,
        ),
      if (week.isNotEmpty)
        TaskGroup(
          title: TasksCopy.groupTitle(TasksCopy.groupThisWeek, week.length),
          tasks: week,
        ),
      if (later.isNotEmpty)
        TaskGroup(
          title: TasksCopy.groupTitle(
            TasksCopy.groupLaterThisMonth,
            later.length,
          ),
          tasks: later,
        ),
    ];
  }

  static List<TaskGroup> _byArea(List<MaintenanceTask> shown) {
    final byArea = <String, List<MaintenanceTask>>{};
    for (final t in shown) {
      byArea.putIfAbsent(TasksCopy.areaOf(t), () => []).add(t);
    }
    final names = byArea.keys.toList()..sort();
    return [
      for (final name in names)
        TaskGroup(
          title: TasksCopy.groupTitle(name, byArea[name]!.length),
          tasks: byArea[name]!,
        ),
    ];
  }

  final DateTime today;

  /// The most overdue task, shown large with its actions.
  final MaintenanceTask? hero;

  /// Overdue tasks after [hero].
  final List<MaintenanceTask> moreOverdue;

  /// Upcoming tasks for this month, grouped.
  final List<TaskGroup> groups;

  /// The next three tasks, for the caught-up view.
  final List<MaintenanceTask> nextUp;

  /// Open tasks matching the search, soonest first (empty without a query).
  final List<MaintenanceTask> matches;

  final int dueTodayCount;

  /// Overdue tasks plus everything due in the next 12 months.
  final int openCount;

  final int monthDone;
  final int monthTotal;
  final int weekDone;

  /// Days until the next upcoming task, or null when nothing is scheduled.
  final int? daysUntilNext;

  int get overdueCount => (hero == null ? 0 : 1) + moreOverdue.length;

  /// A search is active: show [matches] instead of the groups.
  final bool hasQuery;

  /// Nothing overdue and nothing due today.
  bool get caughtUp => overdueCount == 0 && dueTodayCount == 0;
}
