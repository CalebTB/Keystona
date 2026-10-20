import 'package:freezed_annotation/freezed_annotation.dart';

import 'maintenance_task.dart';
import 'task_completion.dart';
import 'task_parent.dart';
import 'task_skip.dart';

part 'task_detail.freezed.dart';

/// Combined state for the Task detail, Log and History screens.
///
/// Assembled by the task detail repository from a single query with nested
/// selects. Never persisted, so no `fromJson`.
@freezed
abstract class TaskDetail with _$TaskDetail {
  const factory TaskDetail({
    required MaintenanceTask task,

    /// Newest first.
    required List<TaskCompletion> completions,

    /// The system, appliance or area this task belongs to.
    TaskParent? parent,

    /// `maintenance_tasks.reminder_days_before`.
    int? reminderDaysBefore,

    /// Skipped occurrences (`task_skips`), newest first.
    @Default(<TaskSkip>[]) List<TaskSkip> skips,
  }) = _TaskDetail;
}
