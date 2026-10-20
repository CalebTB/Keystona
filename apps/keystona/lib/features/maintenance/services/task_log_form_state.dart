import 'package:flutter/widgets.dart';

import '../models/maintenance_task.dart';
import '../models/task_detail.dart';
import '../models/task_finding.dart';
import '../models/task_log_draft.dart';
import 'task_dates.dart';
import 'task_format.dart';
import 'task_log_input.dart';
import 'task_timing.dart';

/// Field state and validation for the Log screen. It owns the text
/// controllers, so the screen disposes it.
class TaskLogFormState extends ChangeNotifier {
  TaskLogFormState({required TaskDetail detail, required DateTime today})
    : _today = today,
      _task = detail.task,
      _parentName = detail.parent?.name,
      _latestDone = detail.completions.isEmpty
          ? null
          : detail.completions.first.completedDate {
    date = TextEditingController(text: TaskLogInput.formatDate(today));
    time = TextEditingController();
    labor = TextEditingController();
    parts = TextEditingController();
    notes = TextEditingController();
    for (final c in [date, time, labor, parts, notes]) {
      c.addListener(notifyListeners);
    }
  }

  final DateTime _today;
  final MaintenanceTask _task;
  final String? _parentName;
  final DateTime? _latestDone;

  late final TextEditingController date;
  late final TextEditingController time;
  late final TextEditingController labor;
  late final TextEditingController parts;
  late final TextEditingController notes;

  TaskDoer _doer = TaskDoer.me;
  TaskPro? _pro;
  final Set<TaskFinding> _findings = {TaskFinding.ok};
  final List<LogPhoto> _photos = [];
  final List<ReceiptOption> _receipts = [];
  bool _addToHistory = true;

  TaskDoer get doer => _doer;
  TaskPro? get pro => _pro;
  Set<TaskFinding> get findings => Set.unmodifiable(_findings);
  List<LogPhoto> get photos => List.unmodifiable(_photos);
  List<ReceiptOption> get receipts => List.unmodifiable(_receipts);
  bool get addToHistory => _addToHistory;

  void setDoer(TaskDoer value) {
    _doer = value;
    notifyListeners();
  }

  void setPro(TaskPro value) {
    _pro = value;
    notifyListeners();
  }

  void toggleFinding(TaskFinding f) {
    if (!_findings.remove(f)) _findings.add(f);
    notifyListeners();
  }

  void addPhoto(LogPhoto photo) {
    _photos.add(photo);
    notifyListeners();
  }

  void removePhotoAt(int index) {
    _photos.removeAt(index);
    notifyListeners();
  }

  void addReceipt(ReceiptOption r) {
    if (_receipts.any((x) => x.id == r.id)) return;
    _receipts.add(r);
    notifyListeners();
  }

  void removeReceipt(String id) {
    _receipts.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  void setAddToHistory(bool value) {
    _addToHistory = value;
    notifyListeners();
  }

  /// The date typed, or null when it is not a real date.
  DateTime? get parsedDate => TaskLogInput.parseDate(date.text);

  /// A real date that is not in the future.
  bool get dateValid {
    final d = parsedDate;
    return d != null && !TaskLogInput.isFuture(d, _today);
  }

  bool get canSave => dateValid;

  /// Labor plus parts.
  double get total =>
      TaskLogInput.parseMoney(labor.text) + TaskLogInput.parseMoney(parts.text);

  /// "$129".
  String get totalText => TaskFormat.money(total);

  /// The line under the date field.
  String get dateHelp {
    final d = parsedDate;
    if (d == null) return 'Use MM / DD / YYYY';
    if (TaskLogInput.isFuture(d, _today)) return "Can't be in the future";
    final latest = _latestDone;
    if (latest != null && d.isBefore(TaskDates.dateOnly(latest))) {
      return 'A past one · the due date stays';
    }
    final timing = TaskTiming.between(_task.dueDate, d);
    final when = switch (timing.kind) {
      TaskTimingKind.early => TaskFormat.timingWords(timing.days, late: false),
      TaskTimingKind.late => TaskFormat.timingWords(timing.days, late: true),
      _ => 'On time',
    };
    if (_task.recurrence == RecurrenceType.none) return when;
    final next = TaskDates.next(
      _task.recurrence,
      d,
      intervalYears: _task.recurrenceIntervalYears,
    );
    return '$when · Next one ${TaskFormat.nextOne(next, season: _task.season)}';
  }

  /// The line under the cost fields.
  String get costHelp {
    if (total <= 0) return 'Leave at \$0 if it was free';
    final p = _parentName?.trim().toLowerCase();
    return p == null || p.isEmpty
        ? "Counts toward the task's lifetime cost"
        : "Counts toward the $p's lifetime cost";
  }

  /// What to save. Only valid when [canSave].
  TaskLogDraft buildDraft() {
    final photos = [
      for (var i = 0; i < _photos.length; i++)
        LogPhoto(
          path: _photos[i].path,
          name: _photos[i].name,
          caption: i == 0 ? 'before' : (i == 1 ? 'after' : null),
        ),
    ];
    return TaskLogDraft(
      completedDate: parsedDate!,
      doer: _doer,
      pro: _pro,
      minutes: TaskLogInput.parseMinutes(time.text),
      laborCost: TaskLogInput.parseMoney(labor.text),
      partsCost: TaskLogInput.parseMoney(parts.text),
      notes: notes.text,
      receiptIds: [for (final r in _receipts) r.id],
      photos: photos,
      findings: [
        for (final f in TaskFinding.values)
          if (_findings.contains(f)) f,
      ],
      addToItemHistory: _addToHistory,
    );
  }

  @override
  void dispose() {
    for (final c in [date, time, labor, parts, notes]) {
      c.removeListener(notifyListeners);
      c.dispose();
    }
    super.dispose();
  }
}
