import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_a.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../tasks_copy.dart';

/// Replaces the overdue card once its task is done: "X done — nothing
/// overdue", with an Undo.
class TasksDoneBanner extends StatelessWidget {
  const TasksDoneBanner({super.key, required this.text, required this.onUndo});

  final String text;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      constraints: BoxConstraints(
        minHeight: a.minControl(AuroraTasksA.doneRowMinHeight),
      ),
      padding: EdgeInsets.only(
        left: a.of(AuroraSpacing.space6),
        right: a.of(AuroraSpacing.space6),
      ),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.xl,
        border: Border.all(
          color: AuroraColors.olive,
          width: AuroraBorders.emphasis,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: a.of(AuroraTasksA.doneBadge),
            height: a.of(AuroraTasksA.doneBadge),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AuroraColors.lime,
            ),
            child: Icon(
              Icons.check,
              size: a.of(AuroraIconSizes.xs),
              color: AuroraColors.olive,
            ),
          ),
          SizedBox(width: a.of(AuroraSpacing.space5)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: a.of(AuroraSpacing.space3),
              ),
              child: Text(text, style: AuroraType.rowTitle),
            ),
          ),
          AuroraPressable(
            onTap: onUndo,
            semanticLabel: TasksCopy.undo,
            enforceTouchTarget: true,
            child: Padding(
              padding: EdgeInsets.only(left: a.of(AuroraSpacing.space3)),
              child: Text(TasksCopy.undo, style: AuroraTasksAType.coralLink),
            ),
          ),
        ],
      ),
    );
  }
}
