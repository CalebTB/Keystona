import 'package:intl/intl.dart';

/// Copy for Review your reminders, Around the house and Turned-off reminders
/// (kit: TaskReview, HomeReminders, SettingsReminders).
abstract final class RemindersCopy {
  // ─── Shared ─────────────────────────────────────────────────────────────

  static const String loadError = "Couldn't load your reminders.";
  static const String changeError = "Couldn't change that reminder. Try again.";
  static const String offWontShow = "Off · won't show up";

  static String turnOnLabel(String name) => 'Turn on: $name';
  static String turnOffLabel(String name) => 'Turn off: $name';

  // ─── Review your reminders ──────────────────────────────────────────────

  static const String reviewBack = 'Home';
  static const String reviewSkip = 'Skip';
  static const String turnAllOn = 'Turn all on';
  static const String setupStep = 'Setup · Step 2 of 4';
  static const String reviewTitle = 'Review your reminders';
  static const String reviewBlurb =
      'We suggested these from what you’ve added and where you live. '
      'Turn off anything that doesn’t fit — you can change this any time.';
  static const String reviewFooter =
      'More show up as you add systems and appliances';
  static const String everyHouse = 'Every house';
  static const String reviewEmptyTitle = 'No reminders to review yet';
  static const String reviewEmptyBody =
      'Add a system or appliance and its reminders show up here.';

  static String ofAllOn(int all) => 'of $all on';

  static String perMonth(int n) => 'About $n a month';

  static String keepLabel(int n) => 'Looks good — keep $n';

  /// "Because you added a furnace".
  static String becauseYouAdded(String item) {
    final lower = item.trim().toLowerCase();
    final article = 'aeiou'.contains(lower.isEmpty ? 'x' : lower[0])
        ? 'an'
        : 'a';
    return 'Because you added $article $lower';
  }

  static String zone(int? zone) => zone == null ? '' : 'Zone $zone';

  // ─── Around the house ───────────────────────────────────────────────────

  static const String homeBack = 'Home profile';
  static const String homeTitle = 'Around the house';
  static const String homeBlurb =
      'Reminders for the house as a whole. Turn off what doesn’t apply — '
      'no sprinklers, no sprinkler reminders.';
  static const String notTiedToSystem = 'Not tied to a system';
  static const String statOn = 'On';
  static const String statOff = 'Turned off';
  static const String statYours = 'Yours';
  static const String yoursTitle = 'Yours';
  static const String yoursSubtitle = 'You made these';
  static const String addReminder = 'Add a reminder';
  static const String homeHint =
      'Add a sprinkler system or sump pump to your home and its reminders '
      'move there automatically.';
  static const String howOften = 'How often';
  static const String edit = 'Edit';
  static const String deleteTitle = 'Delete this reminder?';
  static const String deleteConfirm = 'Delete';
  static const String deleted = 'Reminder deleted';
  static const String deleteError = "Couldn't delete that reminder. Try again.";

  static String homeEyebrow(String? address) =>
      address == null ? notTiedToSystem : '$address · $notTiedToSystem';

  static String climateTitle(int? zone) => zone == null
      ? 'From your climate'
      : 'From your climate · ${RemindersCopy.zone(zone)}';

  static String deleteBody(String name) =>
      '“$name” stops reminding you and leaves your tasks.';

  static String editSemantics(String name) => 'Edit $name';
  static String deleteSemantics(String name) => 'Delete $name';

  /// "Every fall · Added Sep 14".
  static String yoursMeta(String frequency, DateTime added) =>
      '$frequency · Added ${DateFormat('MMM d').format(added)}';

  /// "Off since Aug 30 · You turned it off", or the [reason] it was turned
  /// off when there is one.
  static String offSince(DateTime when, [String? reason]) =>
      'Off since ${DateFormat('MMM d').format(when.toLocal())} · '
      '${_hasText(reason) ? reason!.trim() : youTurnedItOff}';

  static const String youTurnedItOff = 'You turned it off';

  static bool _hasText(String? s) => s != null && s.trim().isNotEmpty;

  // ─── Turned-off reminders ───────────────────────────────────────────────

  static const String settingsBack = 'Settings';
  static const String settingsTitle = 'Turned-off reminders';
  static const String settingsBlurb =
      'Everything you’ve told us to stop suggesting for this home, in one '
      'place. Turning one back on puts it in your tasks at the next due date.';
  static const String seeAll = 'See all';
  static const String turnOn = 'Turn on';
  static const String undo = 'Undo';
  static const String backOn = 'Back on · Next one shows up in your tasks';
  static const String savedForThisHouse =
      'These are saved for this house only. If you move, your new home '
      'starts with a fresh set of suggestions.';
  static const String settingsEmptyTitle = 'Nothing is turned off';
  static const String settingsEmptyBody =
      'Reminders you turn off show up here so you can bring them back.';

  static String settingsEyebrow(String? address) =>
      address == null ? 'Home' : 'Home · $address';

  /// "Off since Sep 12", then " · " and the [reason] when there is one.
  static String settingsOffSince(DateTime when, [String? reason]) {
    final since = 'Off since ${DateFormat('MMM d').format(when.toLocal())}';
    return _hasText(reason) ? '$since · ${reason!.trim()}' : since;
  }
}
