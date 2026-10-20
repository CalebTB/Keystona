import 'maintenance_task.dart';

/// What the long-press menu can do.
enum TaskMenuAction { skip, frequency, open, stop }

/// The row the user picked in the long-press menu.
class TaskMenuChoice {
  const TaskMenuChoice(this.action, [this.frequency]);

  final TaskMenuAction action;

  /// For [TaskMenuAction.frequency]: how often it should repeat.
  final RecurrenceType? frequency;
}
