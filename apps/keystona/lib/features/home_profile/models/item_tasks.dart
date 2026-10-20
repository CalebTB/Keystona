import 'package:intl/intl.dart';

import '../../maintenance/models/maintenance_task.dart';
import '../../maintenance/models/task_schedule.dart';
import '../../maintenance/services/task_format.dart';
import '../../maintenance/tasks_copy.dart';
import 'item_completion.dart';
import 'item_ref.dart';

/// An open task as an ItemTasks card shows it.
class ItemTaskCard {
  const ItemTaskCard({
    required this.task,
    required this.every,
    required this.who,
    required this.pro,
    required this.meta,
    required this.dateLabel,
    required this.soon,
    required this.overdue,
  });

  final MaintenanceTask task;

  /// "EVERY 3 MONTHS".
  final String every;

  /// "DIY" or "PRO".
  final String who;
  final bool pro;

  /// "15 MIN · $25", empty when neither is known.
  final String meta;

  /// "OCT 7".
  final String dateLabel;

  /// Due soon: amber border.
  final bool soon;
  final bool overdue;
}

/// What the Done tab's summary card says.
class ItemDoneSummary {
  const ItemDoneSummary({
    required this.spent,
    required this.times,
    this.sinceYear,
  });

  /// Dollars spent across the completions.
  final double spent;
  final int times;

  /// Year of the oldest completion.
  final int? sinceYear;

  /// "$408".
  String get spentLabel => TaskFormat.money(spent);

  /// "SPENT ON UPKEEP SINCE 2025 · 12 TIMES".
  String get caption {
    final since = sinceYear == null ? '' : ' SINCE $sinceYear';
    return 'SPENT ON UPKEEP$since · $times ${times == 1 ? 'TIME' : 'TIMES'}';
  }
}

/// Pure shaping of an item's tasks for the ItemTasks screen.
abstract final class ItemTasks {
  /// The open tasks that belong to [item], soonest first.
  static List<MaintenanceTask> open(
    Iterable<MaintenanceTask> tasks,
    ItemRef item,
  ) {
    final list = [
      for (final t in tasks)
        if (TaskSchedule.isOpen(t) &&
            (item.isSystem
                ? t.linkedSystemId == item.id
                : t.linkedApplianceId == item.id))
          t,
    ]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }

  static ItemTaskCard card(MaintenanceTask task, DateTime today) {
    final pro = task.diyOrPro == DiyOrPro.professional;
    final cost = task.estimatedCost;
    final minutes = task.estimatedMinutes;
    final parts = <String>[
      if (minutes != null) TasksCopy.duration(minutes),
      if (cost != null) pro ? TaskFormat.estimate(cost) : TaskFormat.money(cost),
    ];
    return ItemTaskCard(
      task: task,
      every: TaskFormat.every(
        task.recurrence,
        season: task.season,
        intervalYears: task.recurrenceIntervalYears,
      ).toUpperCase(),
      who: pro ? TasksCopy.pro : 'DIY',
      pro: pro,
      meta: parts.join(' · '),
      dateLabel: TasksCopy.dateLabel(task.dueDate),
      soon: TaskSchedule.isSoon(task, today),
      overdue: TaskSchedule.isOverdue(task, today),
    );
  }

  /// Totals for the Done tab. Null when nothing has been done.
  static ItemDoneSummary? summary(List<ItemCompletion> done) {
    if (done.isEmpty) return null;
    var spent = 0.0;
    var oldest = done.first.completedOn;
    for (final c in done) {
      spent += c.cost ?? 0;
      if (c.completedOn.isBefore(oldest)) oldest = c.completedOn;
    }
    return ItemDoneSummary(spent: spent, times: done.length, sinceYear: oldest.year);
  }

  /// "JUL 6 · YOU" for a completion in the current year, "OCT 2025 · SUMMIT
  /// HEATING & AIR" for an earlier one.
  static String doneMeta(ItemCompletion c, DateTime today) {
    final same = c.completedOn.year == today.year;
    final date = same
        ? DateFormat.MMMd().format(c.completedOn)
        : DateFormat.yMMM().format(c.completedOn);
    return [date, ?c.doneBy].join(' · ').toUpperCase();
  }
}
