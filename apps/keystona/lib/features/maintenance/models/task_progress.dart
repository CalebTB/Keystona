/// How much the homeowner has finished lately, from the completion log.
///
/// Recurring tasks roll forward on one row, so these counts cannot be read
/// from the task list.
class TaskProgress {
  const TaskProgress({this.doneThisMonth = 0, this.doneThisWeek = 0});

  /// Completions dated in the current calendar month.
  final int doneThisMonth;

  /// Completions dated in the last 7 days, today included.
  final int doneThisWeek;

  static const TaskProgress none = TaskProgress();
}
