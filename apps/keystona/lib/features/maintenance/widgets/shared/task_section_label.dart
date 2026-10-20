import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';

/// Uppercase mono eyebrow above a block, with an optional [trailing] widget
/// (a count, a total, an inline "Edit").
class TaskSectionLabel extends StatelessWidget {
  const TaskSectionLabel({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    // Flexible + spaceBetween, not Expanded + Flexible: that pair splits the
    // row evenly and leaves the trailing widget floating mid-row.
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: a.of(AuroraTasksB.sectionLabelMinHeight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Semantics(
              header: true,
              child: Text(
                title.toUpperCase(),
                style: AuroraType.label.copyWith(
                  color: AuroraColors.inkSecondary,
                ),
              ),
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: a.of(AuroraSpacing.space3)),
            Flexible(child: trailing!),
          ],
        ],
      ),
    );
  }
}
