import 'maintenance_task.dart';
import 'quick_completion.dart';
import 'task_schedule.dart';

/// Which day the work was done.
enum DoneWhen { today, yesterday, picked }

/// The fields of the quick-done sheet, and the completion they describe.
class QuickDoneForm {
  const QuickDoneForm({
    required this.today,
    this.when = DoneWhen.today,
    this.picked,
    this.byPro = false,
  });

  final DateTime today;
  final DoneWhen when;

  /// The day chosen with "Pick a day".
  final DateTime? picked;

  /// A professional did it; otherwise the homeowner.
  final bool byPro;

  QuickDoneForm copyWith({DoneWhen? when, DateTime? picked, bool? byPro}) =>
      QuickDoneForm(
        today: today,
        when: when ?? this.when,
        picked: picked ?? this.picked,
        byPro: byPro ?? this.byPro,
      );

  /// The day the work was done.
  DateTime get completedOn => switch (when) {
    DoneWhen.today => today,
    DoneWhen.yesterday => DateTime(today.year, today.month, today.day - 1),
    DoneWhen.picked => picked ?? today,
  };

  /// When [task] next comes due after being done on [completedOn], or null
  /// for a one-time task.
  DateTime? nextFor(MaintenanceTask task) =>
      task.recurrence == RecurrenceType.none
      ? null
      : TaskSchedule.nextDate(task, base: completedOn);

  /// A cost typed as "$22.00", "22" or "1,200" becomes a number; anything
  /// else (or nothing) is null.
  static double? parseCost(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  QuickCompletion toCompletion({required String cost, required String note}) =>
      QuickCompletion(
        completedOn: completedOn,
        byPro: byPro,
        cost: parseCost(cost),
        note: note.trim().isEmpty ? null : note.trim(),
      );
}
