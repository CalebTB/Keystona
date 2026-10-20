import 'package:flutter/painting.dart';

/// What the detail body can ask the screen to do.
class TaskDetailActions {
  const TaskDetailActions({
    required this.onMarkDone,
    required this.onNotNow,
    required this.onAddDetails,
    required this.onOpenHistory,
    required this.onDelete,
    required this.onEdit,
    this.onUndo,
    this.onOpenParent,
  });

  final VoidCallback onMarkDone;
  final VoidCallback onNotNow;
  final VoidCallback onAddDetails;
  final VoidCallback onOpenHistory;
  final VoidCallback onDelete;

  /// Opens the task form (the "Your notes" Edit link).
  final VoidCallback onEdit;

  /// Null when the done card has nothing to undo.
  final VoidCallback? onUndo;

  /// Null when the parent is an area with no page.
  final VoidCallback? onOpenParent;
}
