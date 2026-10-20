import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_c.dart';
import '../../../../core/widgets/aurora/aurora_field_chrome.dart';
import '../../models/task_draft.dart';
import '../../models/task_form_options.dart';
import '../../task_form_copy.dart';
import 'task_choice_grid.dart';
import 'task_date_field.dart';
import 'task_option_field.dart';

/// First due: the when chips (with the date each stands for), the date field
/// for "Other", and how long before to remind.
class TaskDueSection extends StatelessWidget {
  const TaskDueSection({
    super.key,
    required this.draft,
    required this.today,
    required this.onDue,
    required this.onPickDate,
    required this.onRemind,
  });

  final TaskDraft draft;
  final DateTime today;
  final ValueChanged<DueChoice> onDue;
  final VoidCallback onPickDate;
  final ValueChanged<int> onRemind;

  String _label(DueChoice c) => switch (c) {
    DueChoice.today => TaskFormCopy.dueToday,
    DueChoice.saturday => TaskFormCopy.dueSaturday,
    DueChoice.twoWeeks => TaskFormCopy.dueTwoWeeks,
    DueChoice.other => TaskFormCopy.dueOther,
  };

  String _sub(DueChoice c) {
    switch (c) {
      case DueChoice.today:
        return DateFormat('EEE d').format(draft.dateFor(c, today));
      case DueChoice.saturday || DueChoice.twoWeeks:
        return DateFormat('MMM d').format(draft.dateFor(c, today));
      case DueChoice.other:
        return draft.customDate == null
            ? TaskFormCopy.duePick
            : DateFormat('MMM d').format(draft.customDate!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraSpacing.space2));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuroraFieldLabel(
          label: TaskFormCopy.whenLabel,
          isRequired: false,
        ),
        gap,
        TaskChoiceGrid<DueChoice>(
          choices: [
            for (final c in DueChoice.values)
              TaskChoice(value: c, label: _label(c), sub: _sub(c)),
          ],
          selected: draft.due,
          onSelect: onDue,
          minHeight: AuroraTasksCSizes.dueChipMinHeight,
          labelStyle: AuroraTasksCType.choice,
        ),
        if (draft.due == DueChoice.other) ...[
          gap,
          TaskDateField(date: draft.dueDate(today), onTap: onPickDate),
        ],
        SizedBox(height: a.of(AuroraSpacing.space6)),
        TaskOptionField<int>(
          label: TaskFormCopy.remindLabel,
          sheetTitle: TaskFormCopy.chooseRemind,
          choices: RemindOptions.days,
          value: draft.remindDays,
          labelOf: RemindOptions.label,
          helperText: draft.remindHelp(today),
          onChanged: onRemind,
        ),
      ],
    );
  }
}
