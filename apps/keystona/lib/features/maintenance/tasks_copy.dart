import 'package:intl/intl.dart';

import 'models/maintenance_task.dart';

/// Every string on the Tasks screens, as written in the kit
/// (Tasks, TasksAllYear, TasksCaughtUp, TaskMenu, TaskSkip, TaskDoneQuick).
abstract final class TasksCopy {
  // ─── Tab ────────────────────────────────────────────────────────────────────

  static const String title = 'Tasks';
  static const String addSemantics = 'Create a task';
  static const String searchHint = 'Search or pick a system';
  static const String searchSemantics = 'Search tasks';
  static const String overdueHeading = 'OVERDUE';
  static const String markDone = 'Mark done';
  static const String snooze = 'Snooze';
  static const String doesntApply = "Doesn't apply to my home";
  static const String byDate = 'By date';
  static const String byArea = 'By area';
  static const String groupingTitle = 'Group tasks';
  static const String undo = 'Undo';
  static const String nextUp = 'NEXT UP';
  static const String seeAllUpcoming = 'See all upcoming';
  static const String caughtUpTitle = "You're all caught up";
  static const String caughtUpBody =
      'Nothing overdue and nothing due today. '
      "Your maintenance score is the highest it's been.";
  static const String loadError = "We couldn't load your tasks.";
  static const String noMatches = 'No tasks match that search.';
  static const String matchesHeading = 'MATCHING TASKS';
  static const String pro = 'PRO';

  static String markDoneSemantics(String name) => 'Mark done: $name';

  static String eyebrow(DateTime today, int done, int total) =>
      '${DateFormat.MMMM().format(today).toUpperCase()} · $done OF $total DONE';

  static String subtitle({required int overdue, required int dueToday}) {
    final parts = <String>[
      if (overdue > 0) '$overdue overdue',
      if (dueToday > 0) '$dueToday due today',
    ];
    return parts.isEmpty ? 'All caught up for today' : parts.join(' · ');
  }

  static String caughtUpSubtitle(int? daysUntilNext) {
    if (daysUntilNext == null) return 'Nothing due';
    if (daysUntilNext <= 1) return 'Nothing due until tomorrow';
    return 'Nothing due for $daysUntilNext days';
  }

  static String nothingOverdue(String name) => '$name done — nothing overdue';

  static String daysLate(int days) =>
      days == 1 ? '1 DAY LATE' : '$days DAYS LATE';

  static String groupTitle(String name, int count) => '$name · $count';

  static const String groupToday = 'TODAY';
  static const String groupThisWeek = 'THIS WEEK';
  static const String groupLaterThisMonth = 'LATER THIS MONTH';

  static String seeAll(int count) => 'See all $count tasks';

  static String doneThisWeek(int count) =>
      count == 1 ? '1 task done this week' : '$count tasks done this week';

  // ─── Rows ───────────────────────────────────────────────────────────────────

  static const String todayLabel = 'TODAY';

  static String dateLabel(DateTime date) =>
      DateFormat.MMMd().format(date).toUpperCase();

  /// "EXTERIOR · 45 MIN" — area, then time when known.
  static String meta(MaintenanceTask task, {bool withWho = false}) {
    final parts = <String>[
      areaOf(task),
      if (task.estimatedMinutes != null) duration(task.estimatedMinutes!),
      if (withWho) whoLabel(task.diyOrPro),
    ];
    return parts.join(' · ');
  }

  /// The system the task belongs to, else its area of the house.
  static String areaOf(MaintenanceTask task) =>
      (task.linkedSystemName ?? task.category).toUpperCase();

  static String duration(int minutes) {
    if (minutes < 60) return '$minutes MIN';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours HR' : '$hours HR $rest MIN';
  }

  static String whoLabel(DiyOrPro who) => switch (who) {
    DiyOrPro.diy => 'DIY',
    DiyOrPro.either => 'DIY OR PRO',
    DiyOrPro.professional => 'PRO',
  };

  // ─── Year view ──────────────────────────────────────────────────────────────

  static const String back = 'Tasks';
  static const String allTasksTitle = 'All tasks';
  static const String yourYear = 'YOUR YEAR';

  static String yearEyebrow(int left) => 'NEXT 12 MONTHS · $left TASKS';

  static String overdueCount(int count) => 'OVERDUE · $count';

  static String yearRange(DateTime first) {
    final last = DateTime(first.year, first.month + 11);
    final format = DateFormat('MMM yyyy');
    return '${format.format(first).toUpperCase()} – '
        '${format.format(last).toUpperCase()}';
  }

  static String monthTitle(DateTime month) => DateFormat.yMMMM().format(month);

  static String monthMeta(int tasks, int pros) {
    final count = tasks == 1 ? '1 TASK' : '$tasks TASKS';
    final who = pros == 0
        ? 'ALL DIY'
        : pros == 1
        ? '1 NEEDS A PRO'
        : '$pros NEED A PRO';
    return '$count · $who';
  }

  static String monthChartLabel(DateTime month, int count) =>
      '${DateFormat.yMMMM().format(month)}, '
      '${count == 1 ? '1 task' : '$count tasks'}';

  static String monthLetter(DateTime month) =>
      DateFormat.MMM().format(month).substring(0, 1).toUpperCase();

  static const String monthEmpty = 'Nothing due this month.';

  static String swipeHint(DateTime? previous, DateTime? next) {
    String name(DateTime m) => DateFormat.MMMM().format(m).toUpperCase();
    if (previous != null && next != null) {
      return 'SWIPE FOR ${name(previous)} OR ${name(next)}';
    }
    return 'SWIPE FOR ${name((next ?? previous)!)}';
  }

  /// The season caption for a three-month stretch starting at [first]:
  /// Oct–Dec fall, Jan–Mar winter, Apr–Jun spring, Jul–Sep summer.
  static String season(DateTime first) => switch (first.month) {
    10 || 11 || 12 => 'FALL',
    1 || 2 || 3 => 'WINTER',
    4 || 5 || 6 => 'SPRING',
    _ => 'SUMMER',
  };

  // ─── Menu ───────────────────────────────────────────────────────────────────

  static const String menuLabel = 'Task options';
  static const String menuSkip = 'Skip this time';
  static const String menuFrequency = 'Change how often';
  static const String menuOpen = 'Open the task';
  static const String menuStop = 'Stop reminding me';
  static const String menuStopSub =
      'For this home. Undo any time in Around the house.';
  static const String closeHint = 'TAP ANYWHERE TO CLOSE';
  static const String dismissSemantics = 'Close';

  static String menuSkipSub(String? when) => when == null
      ? 'Marks it skipped. Your score won’t drop.'
      : 'Comes back in $when. Your score won’t drop.';

  static String menuFrequencySub(String now) =>
      'Now $now. Pick what fits your house.';

  static String dueBadge(int days) => switch (days) {
    0 => 'DUE TODAY',
    1 => 'DUE TOMORROW',
    _ => 'DUE IN $days DAYS',
  };

  static String overdueBadge(int days) =>
      days == 1 ? '1 DAY OVERDUE' : '$days DAYS OVERDUE';

  static String previewMeta(MaintenanceTask task) {
    final parts = <String>[
      areaOf(task),
      if (task.recurrence != RecurrenceType.none)
        frequencyName(task.recurrence).toUpperCase(),
    ];
    return parts.join(' · ');
  }

  /// "twice a year", "every 3 months" … for sentences.
  static String frequencyName(RecurrenceType type) => switch (type) {
    RecurrenceType.none => 'one-time',
    RecurrenceType.weekly => 'every week',
    RecurrenceType.biweekly => 'every 2 weeks',
    RecurrenceType.monthly => 'every month',
    RecurrenceType.quarterly => 'every 3 months',
    RecurrenceType.biannual => 'twice a year',
    RecurrenceType.annual => 'every year',
  };

  /// The three frequencies the kit offers, with their chip labels.
  static const List<({RecurrenceType type, String label})> frequencies = [
    (type: RecurrenceType.quarterly, label: 'Every 3 mo'),
    (type: RecurrenceType.biannual, label: 'Twice a year'),
    (type: RecurrenceType.annual, label: 'Yearly'),
  ];

  static String comesBack(DateTime date, DateTime today) {
    if (date.year != today.year && date.difference(today).inDays > 300) {
      return DateFormat.yMMMM().format(date);
    }
    return DateFormat.MMMM().format(date);
  }

  static String skippedTitle(String when) => 'Skipped — see you in $when';
  static String skippedOneTime(String name) => 'Skipped: $name';
  static const String skippedSub = 'Your Home Health score didn’t change.';

  static String stoppedTitle(String name) => 'Stopped reminders: $name';
  static const String stoppedSub =
      'Turn it back on in Home profile → Around the house.';

  static String frequencyTitle(String name, String now) => '$name: $now';
  static String frequencySub(String when) => 'Next one is in $when.';

  static String doneTitle(String name) => '$name done';
  static const String doneSub = 'Next one is scheduled.';

  static String pushedTitle(String name) => 'Pushed back: $name';
  static String pushedSub(String date) => 'Back on your list on $date.';

  // ─── Skip sheet ─────────────────────────────────────────────────────────────

  static const String skipTitle = 'Not now?';
  static const String remindMe = 'REMIND ME';
  static const String whoDidIt = 'WHO DID IT';
  static const String when = 'WHEN';
  static const String cost = 'COST';
  static const String quickNote = 'QUICK NOTE';
  static const String optional = 'Optional';
  static const String costHint = r'$0';
  static const String costHelp = 'ADDS TO UPKEEP SPEND';

  static String dueMeta(MaintenanceTask task) {
    final due = DateFormat('EEE, MMM d').format(task.dueDate).toUpperCase();
    final every = task.recurrence == RecurrenceType.none
        ? ''
        : ' · ${frequencyName(task.recurrence).toUpperCase()}';
    return 'DUE $due$every';
  }

  static String laterDate(DateTime date) =>
      DateFormat('EEEE, MMM d').format(date);

  static String nextDue(DateTime date) => DateFormat.yMMMd().format(date);

  // ─── Quick done sheet ───────────────────────────────────────────────────────

  static const String doneSheetTitle = 'Nice — it’s done';
  static const String save = 'Save';
  static const String addMore = 'Add photos, a receipt or more';
  static const String addMoreSub =
      'GOOD FOR ANYTHING YOU’D WANT TO PROVE LATER';
  static const String pickDay = 'Pick a day';

  static String doneMeta(DateTime? next) => next == null
      ? 'DONE'
      : 'DONE · NEXT ONE ${DateFormat.yMMMd().format(next).toUpperCase()}';

  // ─── Skip sheet reasons ─────────────────────────────────────────────────────

  static const String reasonLater = 'I’ll do it later';
  static const String reasonLaterSub = 'Push it back. It stays on your list.';
  static const String reasonOther = 'Someone else did it';
  static const String reasonOtherSub =
      'Log it as done so the next one is scheduled right.';
  static const String reasonNotApplicable = 'Doesn’t apply to my home';
  static const String reasonNotApplicableSub =
      'Stop reminding me about this one.';
  static const String reasonSkip = 'Just skip this one';

  static String reasonSkipSub(String? when) => when == null
      ? 'Nothing logged.'
      : 'Nothing logged. The next one comes in $when.';

  static const String delayWeek = '1 week';
  static const String delayTwoWeeks = '2 weeks';
  static const String delayMonth = '1 month';
  static const String whoSomeoneElse = 'Someone else';
  static const String whoPro = 'A pro';
  static const String whoMe = 'Me';
  static const String whenToday = 'Today';
  static const String whenYesterday = 'Yesterday';

  static const String pushItBack = 'Push it back';
  static const String logAsDone = 'Log it as done';
  static const String skipThisOne = 'Skip this one';

  static String resultLater(String date, {required bool nextWeek}) =>
      'Moves to ${nextWeek ? 'next ' : ''}$date. '
      'Home Health doesn’t drop while it’s pushed back.';

  static String resultOther(String who, String? next) =>
      'Logged as done today by $who.'
      '${next == null ? '' : ' Next one is due $next.'}';

  static String resultNotApplicable(String name, String where) =>
      'Turned off for $name. It stops counting toward Home Health. '
      'Turn it back on any time in $where.';

  static String resultSkip(String? next) => next == null
      ? 'Marked skipped. A skipped one counts lightly against Home Health.'
      : 'Marked skipped. The next one is due $next — '
            'a skipped one counts lightly against Home Health.';

  static const String aroundTheHouse = 'Home profile → Around the house';

  static String manageWhere(String systemName) => '$systemName → Manage';

  static const String saveError = 'That didn’t save. Please try again.';
}
