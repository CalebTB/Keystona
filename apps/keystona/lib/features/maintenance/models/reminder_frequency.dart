import 'maintenance_task.dart';

/// How a repeating reminder reads on the reminder screens, and which options
/// the "how often" pill offers.
abstract final class ReminderFrequency {
  static const int monthsPerYear = 12;

  /// What the pill offers. The schema stores these four as plain recurrences
  /// (season-based ones such as "Every spring" need a column it does not
  /// have yet).
  static const List<RecurrenceType> choices = [
    RecurrenceType.monthly,
    RecurrenceType.quarterly,
    RecurrenceType.biannual,
    RecurrenceType.annual,
  ];

  /// "Every year", or "Every 3 years" for an annual reminder with an
  /// [intervalYears] of more than one.
  static String label(RecurrenceType recurrence, {int? intervalYears}) {
    if (recurrence == RecurrenceType.annual &&
        intervalYears != null &&
        intervalYears > 1) {
      return 'Every $intervalYears years';
    }
    return _base(recurrence);
  }

  static String _base(RecurrenceType recurrence) => switch (recurrence) {
    RecurrenceType.none => 'Just once',
    RecurrenceType.weekly => 'Every week',
    RecurrenceType.biweekly => 'Every 2 weeks',
    RecurrenceType.monthly => 'Every month',
    RecurrenceType.quarterly => 'Every 3 months',
    RecurrenceType.biannual => 'Twice a year',
    RecurrenceType.annual => 'Every year',
  };

  /// Times a year the reminder comes up.
  static double perYear(RecurrenceType recurrence) => switch (recurrence) {
    RecurrenceType.none => 0,
    RecurrenceType.weekly => 52,
    RecurrenceType.biweekly => 26,
    RecurrenceType.monthly => 12,
    RecurrenceType.quarterly => 4,
    RecurrenceType.biannual => 2,
    RecurrenceType.annual => 1,
  };

  /// "About N a month" for a set of reminders, never below 1 when any exist.
  static int perMonth(Iterable<RecurrenceType> recurrences) {
    var yearly = 0.0;
    var any = false;
    for (final r in recurrences) {
      any = true;
      yearly += perYear(r);
    }
    if (!any) return 0;
    final monthly = (yearly / monthsPerYear).round();
    return monthly < 1 ? 1 : monthly;
  }

  /// A recurrence from the edge function's text, "one time" when unknown.
  static RecurrenceType parse(String? value) => RecurrenceType.values
      .firstWhere((r) => r.value == value, orElse: () => RecurrenceType.none);
}
