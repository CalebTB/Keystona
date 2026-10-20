import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_a.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../tasks_copy.dart';

/// Tasks tab header: the month's progress eyebrow, "Tasks", a subtitle and the
/// outlined "+" button that creates a task.
class TasksHeader extends StatelessWidget {
  const TasksHeader({
    super.key,
    required this.eyebrow,
    required this.subtitle,
    required this.onAdd,
  });

  final String eyebrow;
  final String subtitle;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow, style: AuroraType.label),
              SizedBox(height: a.of(AuroraSpacing.space2)),
              Text(TasksCopy.title, style: AuroraType.h1),
              SizedBox(height: a.of(AuroraSpacing.space2)),
              Text(subtitle, style: AuroraTasksAType.subtitle),
            ],
          ),
        ),
        SizedBox(width: a.of(AuroraSpacing.space5)),
        AuroraPressable(
          onTap: onAdd,
          semanticLabel: TasksCopy.addSemantics,
          child: Container(
            width: AuroraSizes.minTouch,
            height: AuroraSizes.minTouch,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AuroraColors.inkBorder,
                width: AuroraBorders.regular,
              ),
            ),
            child: Icon(
              Icons.add,
              size: a.of(AuroraIconSizes.md),
              color: AuroraColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}
