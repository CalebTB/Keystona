import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/task_progress.dart';
import 'maintenance_repository_provider.dart';
import 'tasks_today_provider.dart';

part 'task_progress_provider.g.dart';

/// Completions this month and this week, for "6 OF 13 DONE" and
/// "4 tasks done this week". Failing to load them only hides those numbers.
@riverpod
Future<TaskProgress> taskProgress(Ref ref) async {
  final today = ref.watch(tasksTodayProvider);
  try {
    return await ref
        .read(maintenanceTasksRepositoryProvider)
        .fetchProgress(today);
  } catch (_) {
    return TaskProgress.none;
  }
}
