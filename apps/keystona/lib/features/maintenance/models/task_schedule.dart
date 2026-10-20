import 'maintenance_task.dart';
import 'task_form_options.dart';

/// Pure date rules for maintenance tasks: what is open, what is overdue and
/// when a recurring task comes back. No Flutter, no Supabase.
abstract final class TaskSchedule {
  /// Midnight of [moment] in local time.
  static DateTime dayOf(DateTime moment) {
    final local = moment.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  /// A task that still needs doing and is not turned off.
  ///
  /// Turned-off reminders are hidden everywhere (kit implementation notes).
  static bool isOpen(MaintenanceTask task) =>
      task.notificationsEnabled &&
      task.status != TaskStatus.completed &&
      task.status != TaskStatus.skipped;

  /// Open and due before [today]. Judged by date, never by the status column,
  /// which lags behind the calendar.
  static bool isOverdue(MaintenanceTask task, DateTime today) =>
      isOpen(task) && dayOf(task.dueDate).isBefore(today);

  /// Whole days between the due date and [today] (negative when not yet due).
  static int daysLate(MaintenanceTask task, DateTime today) =>
      today.difference(dayOf(task.dueDate)).inDays;

  /// Whole days from [today] until the task is due.
  static int daysUntil(MaintenanceTask task, DateTime today) =>
      dayOf(task.dueDate).difference(today).inDays;

  /// How many days before its due date [task] counts as "soon" (amber): the
  /// task's own reminder window (`reminder_days_before`), or the default
  /// lead time when the column is empty.
  static int soonWindowDays(MaintenanceTask task) =>
      task.reminderDaysBefore ?? RemindOptions.defaultDays;

  /// Due within its own reminder window and not overdue. The one rule for
  /// amber: overdue (coral) is checked first by every caller, and a task due
  /// today is soon even with a window of 0.
  static bool isSoon(MaintenanceTask task, DateTime today) {
    final days = daysUntil(task, today);
    return days >= 0 && days <= soonWindowDays(task);
  }

  /// When a recurring [task] comes back after [base] (defaults to its due
  /// date). A one-time task has no next date and returns [base]. An annual
  /// task adds its `recurrenceIntervalYears` (every year when unset); a
  /// [recurrence] override ignores that interval, which belongs to the
  /// task's own recurrence.
  static DateTime nextDate(
    MaintenanceTask task, {
    DateTime? base,
    RecurrenceType? recurrence,
  }) {
    final b = (base ?? task.dueDate).toLocal();
    return switch (recurrence ?? task.recurrence) {
      RecurrenceType.none => b,
      RecurrenceType.weekly => DateTime(b.year, b.month, b.day + 7),
      RecurrenceType.biweekly => DateTime(b.year, b.month, b.day + 14),
      RecurrenceType.monthly => DateTime(b.year, b.month + 1, b.day),
      RecurrenceType.quarterly => DateTime(b.year, b.month + 3, b.day),
      RecurrenceType.biannual => DateTime(b.year, b.month + 6, b.day),
      RecurrenceType.annual => DateTime(
        b.year + (recurrence == null ? task.recurrenceIntervalYears ?? 1 : 1),
        b.month,
        b.day,
      ),
    };
  }

  /// A DATE column value: `YYYY-MM-DD`.
  static String dateColumn(DateTime date) {
    final d = date.toLocal();
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$month-$day';
  }
}
