import 'completion_photo.dart';
import 'task_finding.dart';

/// A photo picked on the Log screen, by local path.
class LogPhoto {
  const LogPhoto({required this.path, required this.name, this.kind});

  final String path;
  final String name;

  /// The role it is saved with: before for the first photo, after for the
  /// second, otherwise null.
  final PhotoKind? kind;
}

/// Who did the work: the homeowner ('diy') or a pro ('contractor').
enum TaskDoer {
  me('diy'),
  pro('contractor');

  const TaskDoer(this.value);

  /// `task_completions.completed_by`.
  final String value;
}

/// A pro from Who to call.
class TaskPro {
  /// The id of a pro that is not in Who to call: built from the contractor
  /// fields of an earlier completion, shown read-only.
  static const String storedId = '';

  const TaskPro({
    required this.id,
    required this.name,
    this.company,
    this.phone,
  });

  final String id;
  final String name;
  final String? company;
  final String? phone;

  /// The name to show: the company when there is one, otherwise the person.
  String get display =>
      company != null && company!.trim().isNotEmpty ? company! : name;
}

/// A document that can be linked to a log as its receipt.
class ReceiptOption {
  const ReceiptOption({required this.id, required this.name});

  final String id;
  final String name;
}

/// What the Log screen saves into `task_completions` (and its photos).
class TaskLogDraft {
  const TaskLogDraft({
    required this.completedDate,
    required this.doer,
    this.pro,
    this.minutes,
    this.laborCost = 0,
    this.partsCost = 0,
    this.notes,
    this.receiptIds = const [],
    this.photos = const [],
    this.findings = const [],
    this.addToItemHistory = false,
  });

  final DateTime completedDate;
  final TaskDoer doer;
  final TaskPro? pro;
  final int? minutes;
  final double laborCost;
  final double partsCost;
  final String? notes;
  final List<String> receiptIds;
  final List<LogPhoto> photos;

  /// "What they found" picks, in the order they are listed on screen.
  final List<TaskFinding> findings;

  /// "Add to the furnace's history" switch.
  final bool addToItemHistory;
}

/// What it takes to take a log back: the completion row, and the schedule it
/// moved (when it did).
class CompletionReceipt {
  const CompletionReceipt({required this.completionId, this.originalDueDate});

  final String completionId;

  /// The due date before the log rolled the schedule forward; null when the
  /// log did not move the schedule (a past entry).
  final DateTime? originalDueDate;
}
