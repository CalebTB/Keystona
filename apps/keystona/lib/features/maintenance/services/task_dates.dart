import '../models/maintenance_task.dart';

/// Pure date maths for the task detail screens. Dates are date-only ("YYYY-MM-DD"
/// DATE columns); every function ignores the time of day.
abstract final class TaskDates {
  /// [d] without its time of day, in local time.
  static DateTime dateOnly(DateTime d) {
    final l = d.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  /// Whole days from [from] to [to] (negative when [to] is earlier).
  static int daysBetween(DateTime from, DateTime to) {
    final a = dateOnly(from);
    final b = dateOnly(to);
    // Compare as UTC so a daylight-saving change never shifts the count.
    return DateTime.utc(
      b.year,
      b.month,
      b.day,
    ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
  }

  /// [d] moved by [days] (negative goes back), date-only.
  static DateTime addDays(DateTime d, int days) {
    final b = dateOnly(d);
    return DateTime(b.year, b.month, b.day + days);
  }

  /// "YYYY-MM-DD", the only format a Postgres DATE column accepts.
  static String dateStr(DateTime dt) {
    final d = dt.toLocal();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  /// Months in a quarter / half year / year.
  static const int _quarter = 3;
  static const int _half = 6;
  static const int _year = 12;
  static const int _week = 7;
  static const int _fortnight = 14;

  /// The due date that follows a completion on [base]. An annual task with
  /// [intervalYears] comes back that many years later instead of one.
  static DateTime next(
    RecurrenceType recurrence,
    DateTime base, {
    int? intervalYears,
  }) {
    final b = dateOnly(base);
    return switch (recurrence) {
      RecurrenceType.none => b,
      RecurrenceType.weekly => DateTime(b.year, b.month, b.day + _week),
      RecurrenceType.biweekly => DateTime(b.year, b.month, b.day + _fortnight),
      RecurrenceType.monthly => _addMonths(b, 1),
      RecurrenceType.quarterly => _addMonths(b, _quarter),
      RecurrenceType.biannual => _addMonths(b, _half),
      RecurrenceType.annual => _addMonths(b, _year * (intervalYears ?? 1)),
    };
  }

  /// Adds months, keeping the day of month unless the target month is
  /// shorter (Jan 31 + 1 month is Feb 28, not Mar 3).
  static DateTime _addMonths(DateTime d, int months) {
    final target = DateTime(d.year, d.month + months);
    final lastDay = DateTime(target.year, target.month + 1, 0).day;
    return DateTime(
      target.year,
      target.month,
      d.day > lastDay ? lastDay : d.day,
    );
  }
}
