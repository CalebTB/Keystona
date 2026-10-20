/// Copy for the Add a task form (kit: AddTask).
abstract final class TaskFormCopy {
  static const String title = 'New task.';
  static const String editTitle = 'Edit task.';
  static const String cancel = 'Cancel';
  static const String save = 'Save task';
  static const String saveError = "Couldn't save task. Try again.";
  static const String loadError =
      "We couldn't load your home. Check your connection and try again.";

  static const String nameLabel = 'Task name';
  static const String namePlaceholder = 'What needs doing?';

  static const String linkLabel = 'For which system or appliance';
  static const String linkPlaceholder = 'Choose one';
  static const String linkHelper =
      "Every task belongs to something — it's how your home score stays honest";
  static const String systemsTab = 'Systems';
  static const String appliancesTab = 'Appliances';
  static const String nothingToPick =
      'Add a system or appliance first and it shows up here.';

  static const String frequencyLabel = 'How often';
  static const String everyLabel = 'Every';

  static String years(int n) => '$n years';

  static const String firstDueTitle = 'First due';
  static const String whenLabel = 'When';
  static const String remindLabel = 'Remind me';
  static const String dueToday = 'Today';
  static const String dueSaturday = 'Saturday';
  static const String dueTwoWeeks = '2 weeks';
  static const String dueOther = 'Other';
  static const String duePick = 'Pick';
  static const String datePickerLabel = 'Pick a date';

  static const String detailsTitle = 'Details';
  static const String notesLabel = 'Notes';
  static const String notesPlaceholder = 'Steps, filter size, which breaker…';
  static const String notesHelper = 'Instructions · materials · safety notes';
  static const String timeLabel = 'Time';
  static const String difficultyLabel = 'Difficulty';
  static const String whoLabel = 'Who does it';

  static const String costTitle = 'Cost';
  static const String estimateLabel = 'Estimate';
  static const String costPrefix = r'$';
  static const String costPlaceholder = '0';
  static const String suppliesLabel = 'Tools & supplies';
  static const String suppliesPlaceholder = 'e.g. 16×25×1 filter';

  static const String optional = 'Optional';

  /// Sheet titles for the select fields.
  static const String chooseTime = 'Time';
  static const String chooseDifficulty = 'Difficulty';
  static const String chooseFrequency = 'How often';
  static const String chooseRemind = 'Remind me';
}
