import 'package:intl/intl.dart';

import 'maintenance_task.dart';
import 'task_form_options.dart';
import 'task_link_option.dart';

/// Everything the Add a task form holds, as plain Dart: validation, the date
/// chips, the one-sentence summary and the database payload. No Flutter, so
/// it is unit-tested directly.
class TaskDraft {
  const TaskDraft({
    this.name = '',
    this.link,
    this.frequency = TaskFrequency.once,
    this.years = YearsRange.initial,
    this.due = DueChoice.today,
    this.customDate,
    this.remindDays = RemindOptions.defaultDays,
    this.remindTouched = false,
    this.notes = '',
    this.minutes,
    this.effort = TaskEffort.easy,
    this.who = TaskWho.me,
    this.cost = '',
    this.supplies = '',
  });

  /// Starts from a saved task (edit mode). Its due date shows under "Other".
  factory TaskDraft.fromTask(MaintenanceTask task, {TaskLinkOption? link}) =>
      TaskDraft(
        name: task.name,
        link: link,
        frequency: TaskFrequency.fromRecurrence(
          task.recurrence,
          intervalYears: task.recurrenceIntervalYears,
        ),
        years: _clampYears(task.recurrenceIntervalYears),
        due: DueChoice.other,
        customDate: dateOnly(task.dueDate),
        notes: task.notes ?? '',
        minutes: task.estimatedMinutes,
        effort: TaskEffort.fromDifficulty(task.difficulty),
        who: TaskWho.fromDiyOrPro(task.diyOrPro),
        cost: _costText(task.estimatedCost),
        supplies: task.suppliesNeeded.join(', '),
      );

  static int _clampYears(int? years) => years == null
      ? YearsRange.initial
      : years.clamp(YearsRange.min, YearsRange.max);

  /// "25" or "25.50" for a saved estimate; empty when there is none.
  static String _costText(double? amount) {
    if (amount == null) return '';
    return amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
  }

  static const int maxName = 80;
  static const int maxNotes = 500;

  /// How far ahead a due date can be picked.
  static const int maxYearsAhead = 10;

  /// Sentinel so [copyWith] can set a nullable field to null.
  static const Object _keep = Object();

  final String name;
  final TaskLinkOption? link;
  final TaskFrequency frequency;

  /// Interval for [TaskFrequency.everyFewYears], saved as
  /// `recurrence_interval_years`. Other frequencies save no interval.
  final int years;
  final DueChoice due;
  final DateTime? customDate;
  final int remindDays;

  /// True once the person changes "Remind me", so editing a task does not
  /// overwrite a lead time the form never showed.
  final bool remindTouched;
  final String notes;
  final int? minutes;
  final TaskEffort effort;
  final TaskWho who;

  /// Free text: an amount such as "25" or "25.50".
  final String cost;

  /// "Tools & supplies", comma separated.
  final String supplies;

  TaskDraft copyWith({
    String? name,
    Object? link = _keep,
    TaskFrequency? frequency,
    int? years,
    DueChoice? due,
    DateTime? customDate,
    int? remindDays,
    String? notes,
    Object? minutes = _keep,
    TaskEffort? effort,
    TaskWho? who,
    String? cost,
    String? supplies,
  }) => TaskDraft(
    name: name ?? this.name,
    link: identical(link, _keep) ? this.link : link as TaskLinkOption?,
    frequency: frequency ?? this.frequency,
    years: years ?? this.years,
    due: due ?? this.due,
    customDate: customDate ?? this.customDate,
    remindDays: remindDays ?? this.remindDays,
    remindTouched: remindDays != null ? true : remindTouched,
    notes: notes ?? this.notes,
    minutes: identical(minutes, _keep) ? this.minutes : minutes as int?,
    effort: effort ?? this.effort,
    who: who ?? this.who,
    cost: cost ?? this.cost,
    supplies: supplies ?? this.supplies,
  );

  // ─── Validation ─────────────────────────────────────────────────────────

  bool get hasName => name.trim().isNotEmpty;
  bool get hasLink => link != null;

  /// The largest estimate `estimated_cost` (NUMERIC(10,2)) can hold.
  static const double maxCost = 99999999.99;

  /// A parsed [cost], or null when empty or not a finite number.
  double? get costAmount {
    final amount = double.tryParse(cost.trim());
    return amount == null || !amount.isFinite ? null : amount;
  }

  /// [costAmount] rounded to cents, as it is saved.
  double? get costToSave {
    final amount = costAmount;
    return amount == null ? null : double.parse(amount.toStringAsFixed(2));
  }

  /// Message under the cost field, or null when it is fine or empty.
  String? get costError {
    if (cost.trim().isEmpty) return null;
    final amount = costAmount;
    return amount == null || amount < 0 || amount > maxCost
        ? costMessage
        : null;
  }

  static const String costMessage = 'Enter an amount like 25 or 25.50';

  /// Save is enabled: a name, something it belongs to, and valid optionals.
  bool get isReady =>
      hasName &&
      hasLink &&
      name.trim().length <= maxName &&
      notes.length <= maxNotes &&
      costError == null;

  // ─── Dates ──────────────────────────────────────────────────────────────

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// The next Saturday after [today] (a Saturday asks for the one after).
  static DateTime nextSaturday(DateTime today) {
    final from = dateOnly(today);
    var ahead = (DateTime.saturday - from.weekday) % DateTime.daysPerWeek;
    if (ahead == 0) ahead = DateTime.daysPerWeek;
    return DateTime(from.year, from.month, from.day + ahead);
  }

  /// Two weeks out from [today].
  static DateTime twoWeeksOut(DateTime today) {
    final from = dateOnly(today);
    return DateTime(from.year, from.month, from.day + 2 * DateTime.daysPerWeek);
  }

  /// The date a chip stands for ([DueChoice.other] is the picked date, or
  /// today until one is picked).
  DateTime dateFor(DueChoice choice, DateTime today) => switch (choice) {
    DueChoice.today => dateOnly(today),
    DueChoice.saturday => nextSaturday(today),
    DueChoice.twoWeeks => twoWeeksOut(today),
    DueChoice.other => customDate ?? dateOnly(today),
  };

  DateTime dueDate(DateTime today) => dateFor(due, today);

  /// Whole days from [today] to the due date.
  int daysUntilDue(DateTime today) =>
      dueDate(today).difference(dateOnly(today)).inDays;

  /// "DUE SOONER" warning applies when the lead time is longer than the wait.
  bool remindsTooEarly(DateTime today) =>
      remindDays > 0 && daysUntilDue(today) < remindDays;

  // ─── Copy that depends on the answers ───────────────────────────────────

  String remindHelp(DateTime today) =>
      remindsTooEarly(today) ? remindSoonerCopy : remindDefaultCopy;

  static const String remindSoonerCopy =
      "Due sooner than that — we'll remind you the morning of";
  static const String remindDefaultCopy = 'A notification on your phone';

  String get whoHelp => switch (who) {
    TaskWho.pro => "When you mark it done, we'll ask who you hired",
    TaskWho.either => "We'll show a pro option if it gets late",
    TaskWho.me => "You'll do it yourself",
  };

  String get _repeatSuffix => switch (frequency) {
    TaskFrequency.once => '',
    TaskFrequency.monthly => ', then every month',
    TaskFrequency.everyThreeMonths => ', then every 3 months',
    TaskFrequency.twiceAYear => ', then twice a year',
    TaskFrequency.yearly => ', then every year',
    TaskFrequency.everyFewYears => ', then every $years years',
  };

  /// "What saving does, in one sentence", or what is still missing.
  String summary(DateTime today) {
    final item = link;
    if (!hasName || item == null) {
      if (!hasName && item == null) {
        return "Add a name and pick what it's for to save.";
      }
      return !hasName ? 'Add a name to save.' : "Pick what it's for to save.";
    }
    final date = dueDate(today);
    final when = date == dateOnly(today)
        ? 'today'
        : DateFormat('EEEE, MMM d').format(date);
    return 'Due $when$_repeatSuffix. It shows up under the '
        '${item.name.toLowerCase()} and in Tasks.';
  }

  // ─── Save ───────────────────────────────────────────────────────────────

  /// Columns written on create and on edit. [category] is the item's category
  /// on create and the task's own on edit.
  Map<String, dynamic> toFields({
    required DateTime today,
    required String category,
    required bool editing,
  }) {
    final item = link!;
    final trimmedNotes = notes.trim();
    return {
      'name': name.trim(),
      'notes': trimmedNotes.isEmpty ? null : trimmedNotes,
      'category': category,
      'due_date': DateFormat('yyyy-MM-dd').format(dueDate(today)),
      'recurrence': frequency.recurrence.value,
      'recurrence_interval_years': intervalYears,
      'estimated_cost': costToSave,
      'difficulty': effort.difficulty.value,
      'diy_or_pro': who.diyOrPro.value,
      'estimated_minutes': minutes,
      'supplies_needed': suppliesList,
      'linked_system_id': item.kind == TaskLinkKind.system ? item.id : null,
      'linked_appliance_id': item.kind == TaskLinkKind.appliance
          ? item.id
          : null,
      if (!editing || remindTouched) 'reminder_days_before': remindDays,
    };
  }

  /// The "every N years" to save: only [TaskFrequency.everyFewYears] has one.
  int? get intervalYears =>
      frequency == TaskFrequency.everyFewYears ? years : null;

  /// A task that never repeats is one-time; everything else is the person's own.
  TaskOrigin get origin =>
      frequency == TaskFrequency.once ? TaskOrigin.oneTime : TaskOrigin.custom;

  /// "16×25×1 filter, MERV 8" as a list.
  List<String> get suppliesList => supplies
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}
