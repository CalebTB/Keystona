import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../../../core/widgets/aurora/aurora_text_field.dart';
import '../../models/task_finding.dart';
import '../shared/task_section_label.dart';
import 'task_finding_chip.dart';

/// "What they found": quick picks and a notes field.
class TaskLogFindingsSection extends StatelessWidget {
  const TaskLogFindingsSection({
    super.key,
    required this.selected,
    required this.onToggle,
    required this.notes,
  });

  final Set<TaskFinding> selected;
  final ValueChanged<TaskFinding> onToggle;
  final TextEditingController notes;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TaskSectionLabel(title: 'What they found'),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        Wrap(
          spacing: a.of(AuroraSpacing.space2),
          runSpacing: a.of(AuroraSpacing.space2),
          children: [
            for (final f in TaskFinding.values)
              TaskFindingChip(
                finding: f,
                selected: selected.contains(f),
                onTap: () => onToggle(f),
              ),
          ],
        ),
        SizedBox(height: a.of(AuroraSpacing.space5)),
        AuroraTextField(
          label: 'Notes',
          controller: notes,
          hintText: 'Anything to remember next time',
          maxLines: AuroraTextField.textareaOpenLines,
          maxLength: AuroraTasksB.notesMax,
          keyboardType: TextInputType.multiline,
        ),
      ],
    );
  }
}
