import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_c.dart';
import '../../../../core/widgets/aurora/aurora_form_section.dart';
import '../../../../core/widgets/aurora/aurora_text_field.dart';
import '../../models/task_draft.dart';
import '../../models/task_link_option.dart';
import '../../models/task_suggestions.dart';
import '../../task_form_copy.dart';
import 'task_cost_section.dart';
import 'task_details_section.dart';
import 'task_due_section.dart';
import 'task_frequency_section.dart';
import 'task_link_section.dart';
import 'task_suggestion_chips.dart';
import 'task_summary_box.dart';

/// The scrolling body of the Add a task form: name, suggestions, what it is
/// for, how often, first due, details, cost, and the one-sentence summary.
class TaskFormBody extends StatelessWidget {
  const TaskFormBody({
    super.key,
    required this.draft,
    required this.options,
    required this.today,
    required this.nameController,
    required this.notesController,
    required this.costController,
    required this.suppliesController,
    required this.onChanged,
    required this.onPickDate,
  });

  final TaskDraft draft;
  final List<TaskLinkOption> options;
  final DateTime today;
  final TextEditingController nameController;
  final TextEditingController notesController;
  final TextEditingController costController;
  final TextEditingController suppliesController;
  final ValueChanged<TaskDraft> onChanged;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraSpacing.space7));
    final suggestions = TaskSuggestions.shown(draft);
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        a.of(AuroraSpacing.screenPadH),
        a.of(AuroraTasksCSizes.formPadTop),
        a.of(AuroraSpacing.screenPadH),
        a.of(AuroraTasksCSizes.formPadBottom),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuroraTextField(
            label: TaskFormCopy.nameLabel,
            controller: nameController,
            required: true,
            hintText: TaskFormCopy.namePlaceholder,
            maxLength: TaskDraft.maxName,
            onChanged: (v) => onChanged(draft.copyWith(name: v)),
          ),
          if (suggestions.isNotEmpty) ...[
            gap,
            TaskSuggestionChips(
              title: TaskSuggestions.titleFor(draft),
              labels: suggestions,
              onPick: (label) =>
                  onChanged(TaskSuggestions.apply(draft, label, options)),
            ),
          ],
          gap,
          TaskLinkSection(
            options: options,
            link: draft.link,
            onChanged: (o) => onChanged(draft.copyWith(link: o)),
          ),
          gap,
          TaskFrequencySection(
            frequency: draft.frequency,
            years: draft.years,
            onFrequency: (f) => onChanged(draft.copyWith(frequency: f)),
            onYears: (y) => onChanged(draft.copyWith(years: y)),
          ),
          AuroraFormSection(
            title: TaskFormCopy.firstDueTitle,
            children: [
              TaskDueSection(
                draft: draft,
                today: today,
                onDue: (d) => onChanged(draft.copyWith(due: d)),
                onPickDate: onPickDate,
                onRemind: (d) => onChanged(draft.copyWith(remindDays: d)),
              ),
            ],
          ),
          TaskDetailsSection(
            draft: draft,
            notesController: notesController,
            onChanged: onChanged,
          ),
          TaskCostSection(
            draft: draft,
            costController: costController,
            suppliesController: suppliesController,
            onChanged: onChanged,
          ),
          SizedBox(height: a.of(AuroraSpacing.formSection)),
          TaskSummaryBox(ready: draft.isReady, text: draft.summary(today)),
        ],
      ),
    );
  }
}
