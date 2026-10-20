import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../models/task_finding.dart';

/// A "What they found" chip. "All good" turns lime with an olive ring when
/// picked; the others turn ink.
class TaskFindingChip extends StatelessWidget {
  const TaskFindingChip({
    super.key,
    required this.finding,
    required this.selected,
    required this.onTap,
  });

  final TaskFinding finding;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final good = finding == TaskFinding.ok;
    final Color fill = !selected
        ? AuroraColors.paper
        : good
        ? AuroraColors.lime
        : AuroraColors.ink;
    final Color fg = !selected
        ? AuroraColors.inkBody
        : good
        ? AuroraColors.olive
        : AuroraColors.paper;
    final Color ring = !selected
        ? AuroraColors.inkInputBorder
        : good
        ? AuroraColors.olive
        : AuroraColors.ink;
    return AuroraPressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: finding.label,
      enforceTouchTarget: true,
      child: Container(
        constraints: BoxConstraints(minHeight: a.of(AuroraSizes.chipHeight)),
        padding: a.symmetric(
          horizontal: AuroraSpacing.space5,
          vertical: AuroraSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: AuroraRadius.full,
          border: Border.all(
            color: ring,
            width: selected && good
                ? AuroraBorders.emphasis
                : AuroraBorders.regular,
          ),
        ),
        child: Text(finding.label, style: AuroraType.chip.copyWith(color: fg)),
      ),
    );
  }
}
