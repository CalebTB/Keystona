import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_a.dart';
import '../../../../core/widgets/loading_skeleton_card.dart';

/// First-frame placeholder that mirrors All tasks: back link and title, search
/// field, the year chart, then a month's rows.
class TasksYearSkeleton extends StatelessWidget {
  const TasksYearSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraSpacing.space8));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoadingSkeletonCard(
          height: a.of(AuroraTasksA.skelTitle),
          borderRadius: AuroraRadius.sm,
        ),
        gap,
        LoadingSkeletonCard(
          height: a.of(AuroraSizes.minTouch),
          borderRadius: AuroraRadius.md,
        ),
        gap,
        LoadingSkeletonCard(
          height: a.of(AuroraTasksA.monthColumn + AuroraTasksA.skelTitle),
          borderRadius: AuroraRadius.banner,
        ),
        gap,
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AuroraRadius.xl,
            border: Border.all(
              color: AuroraColors.inkBorder,
              width: AuroraBorders.regular,
            ),
          ),
          child: Column(
            children: [
              for (var i = 0; i < AuroraTasksA.skelRowCount; i++)
                Padding(
                  padding: a.all(AuroraSpacing.space3),
                  child: LoadingSkeletonCard(
                    height:
                        a.of(AuroraTasksA.skelRow) - a.of(AuroraSpacing.space7),
                    borderRadius: AuroraRadius.md,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
