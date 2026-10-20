import 'task_dates.dart';

/// How urgent an open task is. Overdue is coral, soon is amber.
enum TaskDueTone { overdue, soon, later }

/// An open task's due date compared with today: the tone, and the words for
/// the eyebrow pill and the due card's second line.
class TaskDue {
  const TaskDue._(this.tone, this.days);

  /// Tasks due within this many days are "soon".
  static const int soonWindowDays = 14;

  /// Beyond this many days the pill counts months instead of days.
  static const int monthsAfterDays = 45;
  static const int _daysPerMonth = 30;

  final TaskDueTone tone;

  /// Days until due (negative when overdue).
  final int days;

  factory TaskDue.of(DateTime due, DateTime today) {
    final d = TaskDates.daysBetween(today, due);
    final tone = d < 0
        ? TaskDueTone.overdue
        : d <= soonWindowDays
        ? TaskDueTone.soon
        : TaskDueTone.later;
    return TaskDue._(tone, d);
  }

  static String _plural(int n, String unit) =>
      n == 1 ? '1 $unit' : '$n ${unit}s';

  /// "DUE IN 3 DAYS", "DUE TODAY", "3 DAYS OVERDUE".
  String get pill {
    if (days < 0) return '${_plural(-days, 'day')} overdue';
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    if (days > monthsAfterDays) {
      return 'Due in ${_plural((days / _daysPerMonth).round(), 'month')}';
    }
    return 'Due in ${_plural(days, 'day')}';
  }

  /// "IN 3 DAYS", "TODAY", "3 DAYS AGO".
  String get relative {
    if (days < 0) return '${_plural(-days, 'day')} ago';
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    if (days > monthsAfterDays) {
      return 'In ${_plural((days / _daysPerMonth).round(), 'month')}';
    }
    return 'In ${_plural(days, 'day')}';
  }
}
