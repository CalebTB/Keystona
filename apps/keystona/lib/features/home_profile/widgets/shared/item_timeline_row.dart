/// One entry on an `ItemHistoryTimeline`.
class ItemTimelineRow {
  const ItemTimelineRow({
    required this.dateLabel,
    required this.title,
    this.subtitle,
    this.costLabel,
    this.hollow = false,
  });

  /// "OCT 2025".
  final String dateLabel;
  final String title;

  /// "Summit Heating & Air · receipt saved".
  final String? subtitle;

  /// "$129".
  final String? costLabel;

  /// A hollow dot marks where it all began (the install or purchase row).
  final bool hollow;
}
