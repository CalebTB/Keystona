import 'package:intl/intl.dart';

import '../models/maintenance_task.dart';
import '../models/task_completion.dart';

/// Display strings for the task screens. Pure functions so they are unit
/// tested without Flutter. Eyebrows and pills are uppercased by the widget.
abstract final class TaskFormat {
  static const int _minutesPerHour = 60;
  static const int _daysPerWeek = 7;

  /// "15 min", "1 hr", "1 hr 10 min".
  static String minutes(int total) {
    if (total < _minutesPerHour) return '$total min';
    final h = total ~/ _minutesPerHour;
    final m = total % _minutesPerHour;
    return m == 0 ? '$h hr' : '$h hr $m min';
  }

  /// "$24", "$24.50", "$5,318".
  static String money(double value) {
    final hasCents = (value * 100).round() % 100 != 0;
    final f = NumberFormat(hasCents ? '#,##0.00' : '#,##0');
    return '\$${f.format(value)}';
  }

  /// "~$25": an estimate, not a price.
  static String estimate(double value) => '~${money(value)}';

  /// "Wednesday, Oct 7".
  static String dateLong(DateTime d) => DateFormat('EEEE, MMM d').format(d);

  /// "Oct 4, 2026".
  static String dateShort(DateTime d) => DateFormat('MMM d, y').format(d);

  /// "Sep 30".
  static String dayMonth(DateTime d) => DateFormat('MMM d').format(d);

  /// "Every 3 months", "Every fall", "Every 3 years", "One time".
  static String every(
    RecurrenceType recurrence, {
    String? season,
    int? intervalYears,
  }) {
    if (recurrence == RecurrenceType.annual &&
        intervalYears != null &&
        intervalYears > 1) {
      return 'Every $intervalYears years';
    }
    final s = season?.trim().toLowerCase();
    if (recurrence == RecurrenceType.annual && s != null && s.isNotEmpty) {
      return 'Every $s';
    }
    return switch (recurrence) {
      RecurrenceType.none => 'One time',
      RecurrenceType.weekly => 'Every week',
      RecurrenceType.biweekly => 'Every 2 weeks',
      RecurrenceType.monthly => 'Every month',
      RecurrenceType.quarterly => 'Every 3 months',
      RecurrenceType.biannual => 'Every 6 months',
      RecurrenceType.annual => 'Every year',
    };
  }

  /// "Easy", "Moderate", "Involved", "Pro".
  static String level(TaskDifficulty d) => switch (d) {
    TaskDifficulty.easy => 'Easy',
    TaskDifficulty.moderate => 'Moderate',
    TaskDifficulty.involved => 'Involved',
    TaskDifficulty.professional => 'Pro',
  };

  /// "You", "Either", "A pro".
  static String who(DiyOrPro d) => switch (d) {
    DiyOrPro.diy => 'You',
    DiyOrPro.either => 'Either',
    DiyOrPro.professional => 'A pro',
  };

  /// "1 week before", "2 weeks before", "3 days before", "On the day".
  static String reminder(int days) {
    if (days <= 0) return 'On the day';
    if (days % _daysPerWeek == 0) {
      final w = days ~/ _daysPerWeek;
      return w == 1 ? '1 week before' : '$w weeks before';
    }
    return days == 1 ? '1 day before' : '$days days before';
  }

  /// Where the task came from, for the Schedule card.
  static String added(TaskOrigin origin, {String? parentName}) {
    final p = parentName?.trim().toLowerCase();
    return switch (origin) {
      TaskOrigin.systemGenerated =>
        p == null || p.isEmpty ? 'Suggested for you' : 'Suggested for the $p',
      TaskOrigin.climateTriggered => 'Suggested for your climate',
      TaskOrigin.seasonal => 'Seasonal reminder',
      TaskOrigin.custom || TaskOrigin.oneTime => 'Added by you',
    };
  }

  /// "Fall 2027" for a seasonal task, otherwise "Jan 2027".
  static String nextOne(DateTime next, {String? season}) {
    final s = season?.trim();
    if (s != null && s.isNotEmpty) {
      return '${s[0].toUpperCase()}${s.substring(1).toLowerCase()} ${next.year}';
    }
    return DateFormat('MMM y').format(next);
  }

  /// Labor plus parts, or null when neither was recorded.
  static double? totalCost(TaskCompletion c) {
    final sum = (c.serviceCost ?? 0) + (c.materialsCost ?? 0);
    return sum > 0 ? sum : null;
  }

  /// Who did it: "You" or the pro's company / name.
  static String doneBy(TaskCompletion c) {
    if (c.completedBy != 'contractor') return 'You';
    final company = c.contractorCompany?.trim();
    if (company != null && company.isNotEmpty) return company;
    final name = c.contractorName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'A pro';
  }

  /// "You · 10 min" or "Summit Heating & Air".
  static String doneByLine(TaskCompletion c) {
    final t = c.timeSpentMinutes;
    return t == null ? doneBy(c) : '${doneBy(c)} · ${minutes(t)}';
  }

  /// "3 days early" / "2 days late" / "on time".
  static String timingWords(int days, {required bool late}) {
    final unit = days == 1 ? 'day' : 'days';
    return late ? '$days $unit late' : '$days $unit early';
  }

  /// Initials for an avatar: "Summit Heating & Air" is "SH".
  static String initials(String name) {
    final words = name
        .split(RegExp(r'[^A-Za-z0-9]+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    final first = words.first[0];
    final second = words.length > 1 ? words[1][0] : '';
    return (first + second).toUpperCase();
  }
}
