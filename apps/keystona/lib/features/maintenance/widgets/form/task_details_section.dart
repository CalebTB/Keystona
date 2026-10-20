import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_c.dart';
import '../../../../core/widgets/aurora/aurora_field_chrome.dart';
import '../../../../core/widgets/aurora/aurora_form_section.dart';
import '../../../../core/widgets/aurora/aurora_text_field.dart';
import '../../models/task_draft.dart';
import '../../models/task_form_options.dart';
import '../../task_form_copy.dart';
import 'task_choice_grid.dart';
import 'task_option_field.dart';

/// Details (optional): notes, time, difficulty and who does it.
class TaskDetailsSection extends StatelessWidget {
  const TaskDetailsSection({
    super.key,
    required this.draft,
    required this.notesController,
    required this.onChanged,
  });

  final TaskDraft draft;
  final TextEditingController notesController;
  final ValueChanged<TaskDraft> onChanged;

  /// Lines the notes box can grow to.
  static const int notesMaxLines = 8;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final time = TaskOptionField<int?>(
      label: TaskFormCopy.timeLabel,
      sheetTitle: TaskFormCopy.chooseTime,
      choices: TimeOptions.choices(draft.minutes),
      value: draft.minutes,
      labelOf: TimeOptions.label,
      onChanged: (m) => onChanged(draft.copyWith(minutes: m)),
    );
    final difficulty = TaskOptionField<TaskEffort>(
      label: TaskFormCopy.difficultyLabel,
      sheetTitle: TaskFormCopy.chooseDifficulty,
      choices: TaskEffort.values,
      value: draft.effort,
      labelOf: (e) => e.label,
      onChanged: (e) => onChanged(draft.copyWith(effort: e)),
    );
    return AuroraFormSection(
      title: TaskFormCopy.detailsTitle,
      isOptional: true,
      children: [
        AuroraTextField(
          label: TaskFormCopy.notesLabel,
          controller: notesController,
          hintText: TaskFormCopy.notesPlaceholder,
          helperText: TaskFormCopy.notesHelper,
          maxLines: notesMaxLines,
          maxLength: TaskDraft.maxNotes,
          keyboardType: TextInputType.multiline,
          onChanged: (v) => onChanged(draft.copyWith(notes: v)),
        ),
        _TwoUp(first: time, second: difficulty),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuroraFieldLabel(
              label: TaskFormCopy.whoLabel,
              isRequired: false,
            ),
            SizedBox(height: a.of(AuroraSpacing.space2)),
            TaskChoiceGrid<TaskWho>(
              choices: [
                for (final w in TaskWho.values)
                  TaskChoice(value: w, label: w.label),
              ],
              selected: draft.who,
              onSelect: (w) => onChanged(draft.copyWith(who: w)),
              minHeight: AuroraTasksCSizes.whoMinHeight,
              labelStyle: AuroraTasksCType.whoChoice,
              gap: AuroraSpacing.space3,
            ),
            SizedBox(height: a.of(AuroraSpacing.space2)),
            AuroraFieldHelper(text: draft.whoHelp),
          ],
        ),
      ],
    );
  }
}

/// Two fields side by side; stacked when the text is large.
class _TwoUp extends StatelessWidget {
  const _TwoUp({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = a.of(AuroraSpacing.space4);
    if (a.textScale > AuroraTasksCRatios.stackTextScale) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          first,
          SizedBox(height: gap),
          second,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        SizedBox(width: gap),
        Expanded(child: second),
      ],
    );
  }
}
