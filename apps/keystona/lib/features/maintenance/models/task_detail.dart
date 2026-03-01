import 'package:freezed_annotation/freezed_annotation.dart';

import 'maintenance_task.dart';
import 'task_completion.dart';

part 'task_detail.freezed.dart';

/// Combined state for the Task Detail screen.
///
/// Assembled by [TaskDetailNotifier] from a single Supabase query with nested
/// selects. Never persisted — no [fromJson] needed.
@freezed
abstract class TaskDetail with _$TaskDetail {
  const factory TaskDetail({
    required MaintenanceTask task,
    required List<TaskCompletion> completions,
  }) = _TaskDetail;
}
