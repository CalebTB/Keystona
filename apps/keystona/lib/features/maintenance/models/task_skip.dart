/// One skipped occurrence of a task (a `task_skips` row).
class TaskSkip {
  const TaskSkip({
    required this.id,
    required this.taskId,
    required this.skippedOn,
    required this.dueDate,
    this.reason,
  });

  /// Builds a skip from a `task_skips` row (DATE columns are "YYYY-MM-DD").
  factory TaskSkip.fromRow(Map<String, dynamic> row) => TaskSkip(
    id: row['id'] as String,
    taskId: row['task_id'] as String,
    skippedOn: DateTime.parse(row['skipped_on'] as String),
    dueDate: DateTime.parse(row['due_date'] as String),
    reason: (row['reason'] as String?)?.trim(),
  );

  final String id;
  final String taskId;

  /// The day it was skipped.
  final DateTime skippedOn;

  /// The occurrence that was skipped.
  final DateTime dueDate;

  /// Why, when the person said.
  final String? reason;

  bool get hasReason => reason != null && reason!.isNotEmpty;
}
