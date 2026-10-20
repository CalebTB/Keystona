/// One switch row on Review your reminders.
class ReviewRow {
  const ReviewRow({
    required this.key,
    required this.name,
    required this.frequency,
    required this.on,
  });

  /// Reminder id, or the suggestion's position.
  final String key;
  final String name;

  /// "Every 3 months".
  final String frequency;
  final bool on;
}
