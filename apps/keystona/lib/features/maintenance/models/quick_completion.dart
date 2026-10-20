/// What the quick "Nice — it's done" sheet records alongside a completion.
class QuickCompletion {
  const QuickCompletion({
    required this.completedOn,
    this.byPro = false,
    this.cost,
    this.note,
    this.dueDate,
  });

  /// The day the work was done (a DATE column).
  final DateTime completedOn;

  /// A professional did it; otherwise the homeowner (or someone at home).
  final bool byPro;

  /// What it cost. Filed as the service cost for a pro, materials for DIY.
  final double? cost;

  final String? note;

  /// The due date this completion answers: the occurrence the task was on
  /// before it rolled forward. Filled in when the completion is committed.
  final DateTime? dueDate;

  QuickCompletion withDueDate(DateTime due) => QuickCompletion(
    completedOn: completedOn,
    byPro: byPro,
    cost: cost,
    note: note,
    dueDate: due,
  );
}
