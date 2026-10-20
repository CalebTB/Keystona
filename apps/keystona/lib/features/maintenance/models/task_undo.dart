import 'maintenance_task.dart';

/// What it takes to take a task action back: the task as it was and, for a
/// completion, the log entry that was written, or, for a skip, the skip row.
class TaskUndo {
  const TaskUndo({required this.previous, this.completionId, this.skipId});

  final MaintenanceTask previous;

  /// The completion row to remove when undoing a done.
  final String? completionId;

  /// The `task_skips` row to remove when undoing a skip.
  final String? skipId;
}
