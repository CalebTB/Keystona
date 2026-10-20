import '../models/maintenance_task.dart';
import '../models/quick_completion.dart';
import '../models/task_progress.dart';

/// Reads and writes the property's maintenance tasks and their completions.
///
/// Screens and notifiers depend on this interface through
/// `maintenanceTasksRepositoryProvider`, so tests swap in a fake and never
/// reach Supabase.
abstract interface class MaintenanceTasksRepository {
  /// Every non-deleted task of the user's property, soonest due first.
  Future<List<MaintenanceTask>> fetchTasks();

  /// Completions this month and in the last 7 days.
  Future<TaskProgress> fetchProgress(DateTime today);

  /// Logs a completion of [task] and returns the new row's id.
  Future<String> insertCompletion(
    MaintenanceTask task,
    QuickCompletion completion,
  );

  /// Removes a completion (undo).
  Future<void> deleteCompletion(String completionId);

  /// Records that the occurrence of [task] due on [dueDate] was skipped on
  /// [skippedOn], and returns the new row's id.
  Future<String> insertSkip(
    MaintenanceTask task, {
    required DateTime dueDate,
    required DateTime skippedOn,
    String? reason,
  });

  /// Removes a skip (undo).
  Future<void> deleteSkip(String skipId);

  /// Updates columns of one task row.
  Future<void> updateTask(String taskId, Map<String, dynamic> fields);

  /// Inserts a new task row.
  Future<void> insertTask(Map<String, dynamic> fields);
}
