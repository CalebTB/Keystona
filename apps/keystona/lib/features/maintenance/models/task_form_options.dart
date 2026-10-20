import 'maintenance_task.dart';

/// How often a task repeats, as the Add a task form words it.
enum TaskFrequency {
  once('Just once', RecurrenceType.none),
  monthly('Every month', RecurrenceType.monthly),
  everyThreeMonths('Every 3 months', RecurrenceType.quarterly),
  twiceAYear('Twice a year', RecurrenceType.biannual),
  yearly('Every year', RecurrenceType.annual),

  /// Saved as an annual task with `recurrence_interval_years` set to
  /// [TaskDraft.years].
  everyFewYears('Every few years', RecurrenceType.annual);

  const TaskFrequency(this.label, this.recurrence);

  final String label;

  /// What is written to `maintenance_tasks.recurrence`.
  final RecurrenceType recurrence;

  /// The form option closest to a saved recurrence (used when editing). An
  /// annual task with an [intervalYears] of more than one is "Every few
  /// years".
  static TaskFrequency fromRecurrence(
    RecurrenceType recurrence, {
    int? intervalYears,
  }) => switch (recurrence) {
    RecurrenceType.none => once,
    RecurrenceType.monthly => monthly,
    RecurrenceType.quarterly => everyThreeMonths,
    RecurrenceType.biannual => twiceAYear,
    RecurrenceType.annual =>
      intervalYears != null && intervalYears > 1 ? everyFewYears : yearly,
    RecurrenceType.weekly || RecurrenceType.biweekly => monthly,
  };
}

/// The "when" chips under First due.
enum DueChoice { today, saturday, twoWeeks, other }

/// "Who does it".
enum TaskWho {
  me('Me', DiyOrPro.diy),
  pro('A pro', DiyOrPro.professional),
  either('Either', DiyOrPro.either);

  const TaskWho(this.label, this.diyOrPro);

  final String label;
  final DiyOrPro diyOrPro;

  static TaskWho fromDiyOrPro(DiyOrPro value) => switch (value) {
    DiyOrPro.diy => me,
    DiyOrPro.professional => pro,
    DiyOrPro.either => either,
  };
}

/// Difficulty as the form words it; the schema has four levels.
enum TaskEffort {
  easy('Easy', TaskDifficulty.easy),
  medium('Medium', TaskDifficulty.moderate),
  hard('Hard', TaskDifficulty.involved);

  const TaskEffort(this.label, this.difficulty);

  final String label;
  final TaskDifficulty difficulty;

  static TaskEffort fromDifficulty(TaskDifficulty value) => switch (value) {
    TaskDifficulty.easy => easy,
    TaskDifficulty.moderate => medium,
    TaskDifficulty.involved || TaskDifficulty.professional => hard,
  };
}

/// "Remind me": days before the due date, and the label for it.
abstract final class RemindOptions {
  static const List<int> days = [0, 1, 3, 7, 14];

  /// Default lead time; also what generated tasks use.
  static const int defaultDays = 7;

  static String label(int days) => switch (days) {
    0 => 'The morning of',
    1 => '1 day before',
    14 => '2 weeks before',
    7 => '1 week before',
    _ => '$days days before',
  };
}

/// "Time" options in minutes. Null is "Not sure".
abstract final class TimeOptions {
  static const List<int> minutes = [10, 15, 30, 45, 60, 120, 240];

  static const String unknownLabel = 'Not sure';

  static String label(int? minutes) => switch (minutes) {
    null => unknownLabel,
    60 => '1 hr',
    120 => '2 hr',
    240 => 'Half a day',
    _ => '$minutes min',
  };

  /// [minutes] plus a saved value that is not in the list.
  static List<int?> choices(int? current) => [
    null,
    ...minutes,
    if (current != null && !minutes.contains(current)) current,
  ];
}

/// Limits for the "Every few years" slider.
abstract final class YearsRange {
  static const int min = 2;
  static const int max = 10;
  static const int initial = 3;
}
