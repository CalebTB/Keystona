import 'quick_completion.dart';

/// How the quick-done sheet was closed.
enum QuickDoneOutcome {
  /// "Save": keep the done with the details entered.
  save,

  /// "Undo": it was not done after all.
  undo,

  /// "Add photos, a receipt or more": go to the full log instead.
  addMore,
}

/// The sheet's answer: what the user chose and, for a save, the details.
class QuickDoneResult {
  const QuickDoneResult(this.outcome, [this.completion]);

  final QuickDoneOutcome outcome;
  final QuickCompletion? completion;
}
