import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/task_history.dart';
import 'task_detail_provider.dart';
import 'task_repositories_provider.dart';

part 'task_history_provider.g.dart';

/// The history of one task: its completions with timing, stats and photos.
///
/// Watches [taskDetailProvider], so a log or an undo refreshes it.
@riverpod
Future<TaskHistory> taskHistory(Ref ref, String taskId) async {
  final detail = await ref.watch(taskDetailProvider(taskId).future);
  final photos = await ref.watch(taskDetailRepositoryProvider).completionPhotos(
    [for (final c in detail.completions) c.id],
  );
  return TaskHistory.from(detail, photos);
}
