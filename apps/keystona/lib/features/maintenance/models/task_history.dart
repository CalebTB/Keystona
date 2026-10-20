import '../services/task_format.dart';
import '../services/task_timing.dart';
import 'completion_photo.dart';
import 'maintenance_task.dart';
import 'task_completion.dart';
import 'task_detail.dart';
import 'task_skip.dart';

/// One completion on the history screen.
class TaskHistoryEntry {
  const TaskHistoryEntry({
    required this.completion,
    required this.timing,
    this.photos = const [],
  });

  final TaskCompletion completion;
  final TaskTiming timing;
  final List<CompletionPhoto> photos;
}

/// What one square of the every-time strip stands for.
enum HistoryMark { onTime, late, unknown, skipped }

/// One line of the history log: a completion or a skipped occurrence.
sealed class TaskLogItem {
  const TaskLogItem();

  /// The day it happened: when it was done, or when it was skipped.
  DateTime get date;

  /// What its square in the every-time strip shows.
  HistoryMark get mark;
}

/// A completion on the log.
final class CompletionLogItem extends TaskLogItem {
  const CompletionLogItem(this.entry);

  final TaskHistoryEntry entry;

  @override
  DateTime get date => entry.completion.completedDate;

  @override
  HistoryMark get mark => switch (entry.timing.kind) {
    TaskTimingKind.early || TaskTimingKind.onTime => HistoryMark.onTime,
    TaskTimingKind.late => HistoryMark.late,
    TaskTimingKind.unknown => HistoryMark.unknown,
  };
}

/// A skipped occurrence on the log.
final class SkipLogItem extends TaskLogItem {
  const SkipLogItem(this.skip);

  final TaskSkip skip;

  @override
  DateTime get date => skip.skippedOn;

  @override
  HistoryMark get mark => HistoryMark.skipped;
}

/// Everything the history screen shows, newest entry first, with the stats
/// derived once rather than in `build()`.
class TaskHistory {
  TaskHistory._({
    required this.task,
    required this.parentName,
    required this.entries,
    required this.skips,
    required this.items,
    required this.onTime,
    required this.known,
    required this.totalSpent,
    required this.firstYear,
  });

  /// Builds the history of [detail], attaching [photos] by completion id.
  factory TaskHistory.from(
    TaskDetail detail,
    Map<String, List<CompletionPhoto>> photos,
  ) {
    final timings = TaskTimings.derive(
      detail.task.recurrence,
      detail.completions,
      intervalYears: detail.task.recurrenceIntervalYears,
    );
    final entries = [
      for (final c in detail.completions)
        TaskHistoryEntry(
          completion: c,
          timing: timings[c.id] ?? TaskTiming.unknown,
          photos: photos[c.id] ?? const [],
        ),
    ];
    var onTime = 0;
    var known = 0;
    var spent = 0.0;
    int? firstYear;
    for (final e in entries) {
      if (e.timing.isKnown) {
        known++;
        if (e.timing.isOnTime) onTime++;
      }
      spent += TaskFormat.totalCost(e.completion) ?? 0;
      final y = e.completion.completedDate.year;
      if (firstYear == null || y < firstYear) firstYear = y;
    }
    final items = <TaskLogItem>[
      for (final e in entries) CompletionLogItem(e),
      for (final s in detail.skips) SkipLogItem(s),
    ]..sort(_newestFirst);
    return TaskHistory._(
      task: detail.task,
      parentName: detail.parent?.name,
      entries: entries,
      skips: detail.skips,
      items: items,
      onTime: onTime,
      known: known,
      totalSpent: spent,
      firstYear: firstYear,
    );
  }

  /// Newest first; on the same day a completion comes before a skip.
  static int _newestFirst(TaskLogItem a, TaskLogItem b) {
    final byDate = b.date.compareTo(a.date);
    if (byDate != 0) return byDate;
    return (a is SkipLogItem ? 1 : 0).compareTo(b is SkipLogItem ? 1 : 0);
  }

  final MaintenanceTask task;
  final String? parentName;

  /// Completions only, newest first.
  final List<TaskHistoryEntry> entries;

  /// Skipped occurrences, newest first.
  final List<TaskSkip> skips;

  /// Completions and skips together, newest first.
  final List<TaskLogItem> items;

  /// Completions done on or before their due date, among those with a known
  /// due date ([known]).
  final int onTime;
  final int known;
  final double totalSpent;
  final int? firstYear;

  /// Times it was done (skips are not counted).
  int get count => entries.length;

  /// Nothing done and nothing skipped.
  bool get isEmpty => items.isEmpty;

  /// One mark per log item, oldest to newest, for the every-time strip.
  List<HistoryMark> get marks => [for (final i in items.reversed) i.mark];
}
