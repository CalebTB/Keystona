import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_tasks_a.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// The circle at the left of a task row, inside a 44 pt touch target.
/// Overdue tasks get a coral ring; a done task is olive with a lime check.
class TaskCheckButton extends StatelessWidget {
  const TaskCheckButton({
    super.key,
    required this.onTap,
    required this.semanticLabel,
    this.done = false,
    this.overdue = false,
  });

  final VoidCallback onTap;
  final String semanticLabel;
  final bool done;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final ring = done
        ? AuroraColors.olive
        : overdue
        ? AuroraColors.coral
        : AuroraColors.inkCheckBorder;
    return AuroraPressable(
      onTap: onTap,
      selected: done,
      semanticLabel: semanticLabel,
      enforceTouchTarget: true,
      child: Container(
        width: a.of(AuroraTasksA.checkCircle),
        height: a.of(AuroraTasksA.checkCircle),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? AuroraColors.olive : null,
          border: Border.all(color: ring, width: AuroraTasksA.checkBorder),
        ),
        child: done
            ? Icon(
                Icons.check,
                size: a.of(AuroraTasksA.checkGlyph),
                color: AuroraColors.lime,
              )
            : null,
      ),
    );
  }
}
