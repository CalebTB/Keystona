import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/task_progress.dart';
import '../models/tasks_tab_data.dart';
import '../models/tasks_year_data.dart';
import 'maintenance_tasks_provider.dart';
import 'task_progress_provider.dart';
import 'tasks_today_provider.dart';

part 'tasks_tab_provider.g.dart';

/// The Tasks tab, worked out from the task list. Empty while it loads; the
/// screen reads the load state from `maintenanceTasksProvider`.
@riverpod
TasksTabData tasksTabData(
  Ref ref, {
  TaskGrouping grouping = TaskGrouping.date,
  String query = '',
}) {
  return TasksTabData.from(
    ref.watch(maintenanceTasksProvider).value ?? const [],
    today: ref.watch(tasksTodayProvider),
    progress: ref.watch(taskProgressProvider).value ?? TaskProgress.none,
    grouping: grouping,
    query: query,
  );
}

/// All tasks: the overdue list and the next 12 months.
@riverpod
TasksYearData tasksYearData(Ref ref, {String query = ''}) {
  return TasksYearData.from(
    ref.watch(maintenanceTasksProvider).value ?? const [],
    today: ref.watch(tasksTodayProvider),
    query: query,
  );
}
