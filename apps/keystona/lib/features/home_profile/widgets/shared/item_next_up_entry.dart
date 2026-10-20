/// One upcoming task as the item detail and ItemTasks screens show it.
class ItemNextUpEntry {
  const ItemNextUpEntry({
    required this.id,
    required this.name,
    required this.metaLine,
    required this.dateLabel,
    this.soon = false,
    this.overdue = false,
    this.done = false,
    this.isPro = false,
  });

  final String id;
  final String name;

  /// "HVAC · 15 MIN · $25".
  final String metaLine;

  /// "OCT 7", or "DONE" when [done].
  final String dateLabel;

  /// Due soon: amber rule.
  final bool soon;
  final bool overdue;
  final bool done;

  /// A job for a pro: "PRO" is added to the meta line.
  final bool isPro;
}
