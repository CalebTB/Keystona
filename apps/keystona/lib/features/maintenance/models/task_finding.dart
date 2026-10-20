/// What a pro found, as quick picks on the Log screen.
enum TaskFinding {
  ok('ok', 'All good'),
  soon('soon', 'Needs a part soon'),
  fix('fix', 'Needed a repair'),
  quote('quote', 'Gave a quote');

  const TaskFinding(this.value, this.label);

  /// What is stored in `task_completions.findings`.
  final String value;
  final String label;

  /// The finding stored as [value], or null for a value this app does not
  /// know (written by a newer version).
  static TaskFinding? fromValue(String value) {
    for (final f in values) {
      if (f.value == value) return f;
    }
    return null;
  }
}
