import 'package:intl/intl.dart';

/// Date formatting and comparison helpers for Keystona.
///
/// Named [AppDateUtils] to avoid conflict with Flutter's built-in [DateUtils].
/// Always use this class instead of formatting dates inline.
abstract final class AppDateUtils {
  static final _dateFormatter = DateFormat('MMM d, y');
  static final _shortDateFormatter = DateFormat('MMM d');
  static final _monthYearFormatter = DateFormat('MMMM y');

  /// Returns a human-readable relative date string.
  ///
  /// Examples: "just now", "3 minutes ago", "2 hours ago",
  /// "yesterday", "3 days ago", "in 2 days", "in 1 week".
  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    // Future dates
    if (date.isAfter(now)) {
      final futureDiff = date.difference(now);
      if (futureDiff.inDays == 0) return 'today';
      if (futureDiff.inDays == 1) return 'in 1 day';
      if (futureDiff.inDays < 7) return 'in ${futureDiff.inDays} days';
      if (futureDiff.inDays < 14) return 'in 1 week';
      if (futureDiff.inDays < 30) return 'in ${(futureDiff.inDays / 7).floor()} weeks';
      if (futureDiff.inDays < 60) return 'in 1 month';
      return 'in ${(futureDiff.inDays / 30).floor()} months';
    }

    // Past dates
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) {
      return diff.inMinutes == 1
          ? '1 minute ago'
          : '${diff.inMinutes} minutes ago';
    }
    if (diff.inHours < 24) {
      return diff.inHours == 1 ? '1 hour ago' : '${diff.inHours} hours ago';
    }
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 14) return '1 week ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    if (diff.inDays < 60) return '1 month ago';
    return '${(diff.inDays / 30).floor()} months ago';
  }

  /// Formats [date] as "Jan 15, 2026".
  static String formatDate(DateTime date) => _dateFormatter.format(date);

  /// Formats [date] as "Jan 15".
  static String formatShortDate(DateTime date) =>
      _shortDateFormatter.format(date);

  /// Formats [date] as "January 2026".
  static String formatMonthYear(DateTime date) =>
      _monthYearFormatter.format(date);

  /// Returns true when [dueDate] is strictly in the past (before today's start).
  static bool isOverdue(DateTime dueDate) {
    final today = _startOfDay(DateTime.now());
    return dueDate.isBefore(today);
  }

  /// Returns true when [dueDate] falls on today (same calendar day).
  static bool isDueToday(DateTime dueDate) {
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  /// Returns true when [dueDate] is within the next [withinDays] days
  /// (exclusive of today and overdue dates).
  static bool isDueSoon(DateTime dueDate, {int withinDays = 7}) {
    if (isOverdue(dueDate) || isDueToday(dueDate)) return false;
    final today = _startOfDay(DateTime.now());
    final cutoff = today.add(Duration(days: withinDays));
    return dueDate.isBefore(cutoff);
  }

  static DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
