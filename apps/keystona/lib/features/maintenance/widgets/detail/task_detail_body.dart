import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../models/maintenance_task.dart';
import '../../models/task_completion.dart';
import '../../models/task_detail.dart';
import '../../services/task_dates.dart';
import '../../services/task_detail_view.dart';
import '../../services/task_due.dart';
import '../../services/task_format.dart';
import '../../services/task_instructions.dart';
import '../../services/task_timing.dart';
import '../shared/task_fact_card.dart';
import '../shared/task_status_pill.dart';
import '../shared/task_tone_colors.dart';
import 'task_detail_actions.dart';
import 'task_detail_header.dart';
import 'task_done_card.dart';
import 'task_due_card.dart';
import 'task_history_section.dart';
import 'task_needs_section.dart';
import 'task_notes_section.dart';
import 'task_parent_card.dart';
import 'task_schedule_section.dart';
import 'task_spec_tiles.dart';
import 'task_steps_section.dart';
import '../shared/task_section_label.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// The task detail content: header, due or done card, parent, quick facts,
/// how-to, what you need, history, schedule, and delete.
class TaskDetailBody extends StatelessWidget {
  const TaskDetailBody({
    super.key,
    required this.detail,
    required this.view,
    required this.today,
    required this.actions,
    this.busy = false,
  });

  final TaskDetail detail;
  final TaskDetailView view;

  /// Date-only.
  final DateTime today;
  final TaskDetailActions actions;
  final bool busy;

  /// Entries shown on the detail's history card; the rest are on History.
  static const int historyPreview = 4;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final task = detail.task;
    final steps = TaskInstructions.steps(task.instructions);
    final gap = SizedBox(height: a.of(AuroraTasksB.sectionGap));
    final every = TaskFormat.every(
      task.recurrence,
      season: task.season,
      intervalYears: task.recurrenceIntervalYears,
    );
    final notes = task.notes?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TaskDetailHeader(
          eyebrow: '${task.category} · $every',
          pill: _pill(),
          title: task.name,
          description: task.description,
        ),
        gap,
        _statusCard(),
        if (detail.parent != null) ...[gap, _parent(a)],
        gap,
        TaskSpecTiles(specs: _specs(task)),
        if (steps.isNotEmpty) ...[gap, TaskStepsSection(steps: steps)],
        if (TaskNeedsSection.hasContent(
          task.suppliesNeeded,
          task.toolsNeeded,
        )) ...[
          gap,
          TaskNeedsSection(
            supplies: task.suppliesNeeded,
            tools: task.toolsNeeded,
          ),
        ],
        if (notes != null && notes.isNotEmpty) ...[
          gap,
          TaskNotesSection(notes: notes, onEdit: actions.onEdit),
        ],
        gap,
        _history(),
        gap,
        TaskScheduleSection(facts: _scheduleFacts(task)),
        gap,
        Center(
          child: AuroraPressable(
            onTap: actions.onDelete,
            semanticLabel: 'Delete this task',
            enforceTouchTarget: true,
            child: Padding(
              padding: a.symmetric(horizontal: AuroraSpacing.space7),
              child: Text(
                'Delete this task',
                style: AuroraType.buttonSm.copyWith(
                  color: AuroraColors.coralDeep,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget? _pill() {
    final due = view.due;
    return switch (view.phase) {
      TaskPhase.open when due != null => TaskStatusPill(
        label: due.pill,
        ring: due.tone.ring,
        text: due.tone.text,
      ),
      TaskPhase.done when view.doneToday => const TaskStatusPill(
        label: 'Done today',
        ring: AuroraColors.olive,
        text: AuroraColors.olive,
        check: true,
      ),
      TaskPhase.skipped => const TaskStatusPill(
        label: 'Skipped',
        ring: AuroraColors.inkBorderStrong,
        text: AuroraColors.inkSecondary,
      ),
      _ => null,
    };
  }

  Widget _statusCard() {
    final task = detail.task;
    switch (view.phase) {
      case TaskPhase.open:
        final due = view.due!;
        return TaskDueCard(
          ring: due.tone.ring,
          accent: due.tone.text,
          title: 'Due ${TaskFormat.dateLong(task.dueDate)}',
          subtitle: _dueSubtitle(due),
          busy: busy,
          onMarkDone: actions.onMarkDone,
          onNotNow: actions.onNotNow,
          onAddDetails: actions.onAddDetails,
        );
      case TaskPhase.done:
        return TaskDoneCard(
          kind: TaskResultKind.done,
          title: view.doneTitle!,
          subtitle: view.nextLine,
          onUndo: view.canUndo ? actions.onUndo : null,
        );
      case TaskPhase.skipped:
        return TaskDoneCard(
          kind: TaskResultKind.skipped,
          title: 'Skipped',
          subtitle: task.skipReason,
        );
    }
  }

  String _dueSubtitle(TaskDue due) {
    final days = detail.task.reminderDaysBefore;
    final reminder = days == null
        ? null
        : TaskDates.addDays(detail.task.dueDate, -days);
    final sent =
        reminder != null && TaskDates.daysBetween(today, reminder) <= 0;
    return [
      due.relative,
      if (sent) 'Reminder went out ${TaskFormat.dayMonth(reminder)}',
    ].join(' · ');
  }

  Widget _parent(AuroraScale a) {
    final parent = detail.parent!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TaskSectionLabel(title: 'For'),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        TaskParentCard(parent: parent, onTap: actions.onOpenParent),
      ],
    );
  }

  List<TaskSpec> _specs(MaintenanceTask task) => [
    if (task.estimatedMinutes != null)
      TaskSpec('Time', TaskFormat.minutes(task.estimatedMinutes!)),
    TaskSpec('Level', TaskFormat.level(task.difficulty)),
    TaskSpec('Who', TaskFormat.who(task.diyOrPro)),
    if (task.estimatedCost != null)
      TaskSpec('Cost', TaskFormat.estimate(task.estimatedCost!)),
  ];

  Widget _history() {
    final completions = detail.completions;
    return TaskHistorySection(
      count: completions.length,
      onTimeText: view.known == 0
          ? null
          : 'On time ${view.onTime} of ${view.known}',
      onOpen: actions.onOpenHistory,
      rows: [
        for (var i = 0; i < completions.length && i < historyPreview; i++)
          _row(completions[i], isNewest: i == 0),
      ],
    );
  }

  TaskHistoryRow _row(TaskCompletion c, {required bool isNewest}) {
    final timing = view.timings[c.id] ?? TaskTiming.unknown;
    final words = switch (timing.kind) {
      TaskTimingKind.early => TaskFormat.timingWords(timing.days, late: false),
      TaskTimingKind.late => TaskFormat.timingWords(timing.days, late: true),
      TaskTimingKind.onTime => 'On time',
      TaskTimingKind.unknown => null,
    };
    final cost = TaskFormat.totalCost(c);
    return TaskHistoryRow(
      eyebrow: [TaskFormat.dateShort(c.completedDate), ?words].join(' · '),
      timing: timing.kind,
      who: TaskFormat.doneByLine(c),
      amount: cost == null ? null : TaskFormat.money(cost),
      justDone: isNewest && view.doneToday,
    );
  }

  List<TaskFact> _scheduleFacts(MaintenanceTask task) {
    final next = view.nextAfterThis;
    final days = detail.task.reminderDaysBefore;
    return [
      TaskFact(
        'Repeats',
        TaskFormat.every(
          task.recurrence,
          season: task.season,
          intervalYears: task.recurrenceIntervalYears,
        ),
      ),
      if (next != null) TaskFact('Next after this', TaskFormat.dateShort(next)),
      if (days != null) TaskFact('Reminder', TaskFormat.reminder(days)),
      TaskFact(
        'Added',
        TaskFormat.added(task.taskOrigin, parentName: detail.parent?.name),
      ),
    ];
  }
}
