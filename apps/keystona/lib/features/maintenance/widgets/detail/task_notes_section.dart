import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../../../core/theme/aurora_tasks_wire.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../shared/task_section_label.dart';

/// "Your notes": what the homeowner wrote for this task, with an Edit link
/// that opens the task form where the notes are written.
class TaskNotesSection extends StatelessWidget {
  const TaskNotesSection({
    super.key,
    required this.notes,
    required this.onEdit,
  });

  final String notes;
  final VoidCallback onEdit;

  /// Copy of the section's label.
  static const String title = 'Your notes';

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TaskSectionLabel(
          title: title,
          trailing: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: AuroraPressable(
              onTap: onEdit,
              semanticLabel: 'Edit your notes',
              enforceTouchTarget: true,
              child: Text(
                'Edit',
                style: AuroraType.buttonSm.copyWith(color: AuroraColors.ink),
              ),
            ),
          ),
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        Container(
          padding: EdgeInsetsDirectional.only(
            start: a.of(AuroraSpacing.space6),
            top: a.of(AuroraTasksB.hairlineGap),
            bottom: a.of(AuroraTasksB.hairlineGap),
          ),
          decoration: const BoxDecoration(
            border: BorderDirectional(
              start: BorderSide(
                color: AuroraTasksWire.notesRule,
                width: AuroraBorders.indicator,
              ),
            ),
          ),
          child: Text(notes, style: AuroraTasksBType.step),
        ),
      ],
    );
  }
}
