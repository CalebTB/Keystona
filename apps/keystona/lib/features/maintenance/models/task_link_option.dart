/// Whether a task belongs to a system or an appliance.
enum TaskLinkKind { system, appliance }

/// A system or appliance a new task can belong to (the "For which system or
/// appliance" picker).
class TaskLinkOption {
  const TaskLinkOption({
    required this.id,
    required this.kind,
    required this.name,
    required this.category,
    required this.categoryLabel,
    this.location,
    this.taskCount = 0,
  });

  final String id;
  final TaskLinkKind kind;
  final String name;

  /// Value written to `maintenance_tasks.category` for a task on this item.
  final String category;

  /// "HVAC", "Plumbing", "Laundry"...
  final String categoryLabel;

  /// "Basement", "Garage"... when the item records one.
  final String? location;

  /// Tasks already on this item.
  final int taskCount;

  /// "SYSTEM · HVAC" under the name once the item is chosen.
  String get fieldMeta {
    final owner = kind == TaskLinkKind.system ? 'System' : 'Appliance';
    return '$owner · $categoryLabel'.toUpperCase();
  }

  /// "HVAC · BASEMENT · 3 TASKS" under the name in the picker list.
  String get listMeta {
    final tasks = switch (taskCount) {
      0 => 'No tasks',
      1 => '1 task',
      _ => '$taskCount tasks',
    };
    final loc = location;
    return [
      categoryLabel,
      if (loc != null && loc.trim().isNotEmpty) loc.trim(),
      tasks,
    ].join(' · ').toUpperCase();
  }

  /// Matches a catalog hint ("furnace", "gutters") against the item name.
  bool matches(String hint) => name.toLowerCase().contains(hint.toLowerCase());
}
