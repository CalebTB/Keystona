/// One finished occurrence of one of an item's tasks, for the ItemTasks Done
/// tab (`task_completions` joined to its task).
class ItemCompletion {
  const ItemCompletion({
    required this.id,
    required this.taskName,
    required this.completedOn,
    this.doneBy,
    this.cost,
  });

  /// Reads a row from `task_completions` with its `task:maintenance_tasks`.
  factory ItemCompletion.fromRow(Map<String, dynamic> row) {
    final task = row['task'] as Map<String, dynamic>?;
    final service = (row['service_cost'] as num?)?.toDouble() ?? 0;
    final materials = (row['materials_cost'] as num?)?.toDouble() ?? 0;
    final total = service + materials;
    final contractor = row['completed_by'] == 'contractor';
    String? named(String key) {
      final v = (row[key] as String?)?.trim();
      return v == null || v.isEmpty ? null : v;
    }

    return ItemCompletion(
      id: row['id'] as String,
      taskName: (task?['name'] as String?) ?? '',
      completedOn: DateTime.parse(row['completed_date'] as String),
      doneBy: contractor
          ? (named('contractor_company') ?? named('contractor_name') ?? 'A pro')
          : 'You',
      cost: total > 0 ? total : null,
    );
  }

  final String id;
  final String taskName;
  final DateTime completedOn;

  /// "You", or the pro's company or name.
  final String? doneBy;

  /// Labor plus parts in dollars; null when none was recorded.
  final double? cost;
}
