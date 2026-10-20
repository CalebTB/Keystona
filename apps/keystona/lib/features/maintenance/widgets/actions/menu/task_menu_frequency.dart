import 'package:flutter/material.dart';

import '../../../../../core/theme/aurora_colors.dart';
import '../../../../../core/theme/aurora_radius.dart';
import '../../../../../core/theme/aurora_scale.dart';
import '../../../../../core/theme/aurora_sizes.dart';
import '../../../../../core/theme/aurora_spacing.dart';
import '../../../../../core/theme/aurora_tasks_a.dart';
import '../../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../../models/maintenance_task.dart';
import '../../../tasks_copy.dart';

/// The three "how often" chips that open under "Change how often".
class TaskMenuFrequency extends StatelessWidget {
  const TaskMenuFrequency({
    super.key,
    required this.current,
    required this.onPick,
  });

  final RecurrenceType current;
  final ValueChanged<RecurrenceType> onPick;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Padding(
      padding: EdgeInsets.only(
        left: a.of(AuroraTasksA.menuChipInset),
        right: a.of(AuroraSpacing.space7),
        bottom: a.of(AuroraSpacing.space6),
      ),
      child: Row(
        children: [
          for (var i = 0; i < TasksCopy.frequencies.length; i++) ...[
            if (i > 0) SizedBox(width: a.of(AuroraSpacing.space2)),
            Expanded(
              child: _Chip(
                label: TasksCopy.frequencies[i].label,
                selected: TasksCopy.frequencies[i].type == current,
                onTap: () => onPick(TasksCopy.frequencies[i].type),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: label,
      child: Container(
        alignment: Alignment.center,
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraTasksA.frequencyChipHeight),
        ),
        padding: EdgeInsets.symmetric(horizontal: a.of(AuroraSpacing.space2)),
        decoration: BoxDecoration(
          borderRadius: AuroraRadius.tile,
          color: selected ? AuroraColors.ink : AuroraColors.paper,
          border: selected
              ? null
              : Border.all(
                  color: AuroraColors.inkInputBorder,
                  width: AuroraBorders.regular,
                ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AuroraTasksAType.frequencyChip.copyWith(
            color: selected ? AuroraColors.paper : AuroraColors.inkBody,
          ),
        ),
      ),
    );
  }
}
