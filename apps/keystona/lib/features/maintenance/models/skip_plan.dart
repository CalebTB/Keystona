import 'maintenance_task.dart';
import 'task_schedule.dart';
import '../tasks_copy.dart';

/// Why the user is not doing a task right now (kit: TaskSkip).
enum SkipReason { later, other, notApplicable, skip }

/// How far to push a task back.
enum SkipDelay {
  oneWeek(7),
  twoWeeks(14),
  oneMonth(30);

  const SkipDelay(this.days);
  final int days;
}

/// The choices made on the "Not now?" sheet, and what they will do.
class SkipPlan {
  const SkipPlan({
    this.reason = SkipReason.later,
    this.delay = SkipDelay.oneWeek,
    this.byPro = false,
  });

  final SkipReason reason;
  final SkipDelay delay;

  /// For [SkipReason.other]: a professional did it, otherwise someone at home.
  final bool byPro;

  SkipPlan copyWith({SkipReason? reason, SkipDelay? delay, bool? byPro}) =>
      SkipPlan(
        reason: reason ?? this.reason,
        delay: delay ?? this.delay,
        byPro: byPro ?? this.byPro,
      );

  /// Where "push it back" moves [task]: [delay] after its due date, or after
  /// [today] when it is already overdue.
  DateTime pushedTo(MaintenanceTask task, DateTime today) {
    final due = TaskSchedule.dayOf(task.dueDate);
    final base = due.isBefore(today) ? today : due;
    return DateTime(base.year, base.month, base.day + delay.days);
  }

  /// When a recurring task next comes due after being done or skipped today,
  /// or null for a one-time task.
  static DateTime? nextAfter(MaintenanceTask task, DateTime from) =>
      task.recurrence == RecurrenceType.none
      ? null
      : TaskSchedule.nextDate(task, base: from);

  /// The sentence in the result box.
  String result(MaintenanceTask task, DateTime today) {
    switch (reason) {
      case SkipReason.later:
        return TasksCopy.resultLater(
          TasksCopy.laterDate(pushedTo(task, today)),
          nextWeek: delay == SkipDelay.oneWeek,
        );
      case SkipReason.other:
        final next = nextAfter(task, today);
        return TasksCopy.resultOther(
          byPro ? 'a pro' : 'someone else',
          next == null ? null : TasksCopy.nextDue(next),
        );
      case SkipReason.notApplicable:
        return TasksCopy.resultNotApplicable(
          task.name,
          task.linkedSystemName == null
              ? TasksCopy.aroundTheHouse
              : TasksCopy.manageWhere(task.linkedSystemName!),
        );
      case SkipReason.skip:
        final next = nextAfter(task, task.dueDate);
        return TasksCopy.resultSkip(
          next == null ? null : TasksCopy.nextDue(next),
        );
    }
  }

  /// The label of the big button.
  String get cta => switch (reason) {
    SkipReason.later => TasksCopy.pushItBack,
    SkipReason.other => TasksCopy.logAsDone,
    SkipReason.notApplicable => TasksCopy.menuStop,
    SkipReason.skip => TasksCopy.skipThisOne,
  };
}
