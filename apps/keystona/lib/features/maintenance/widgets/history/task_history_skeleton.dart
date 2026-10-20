import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../../../core/widgets/loading_skeleton_card.dart';

/// Shimmer placeholder that mirrors History: header, three tiles, the strip
/// and the log card.
class TaskHistorySkeleton extends StatelessWidget {
  const TaskHistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraTasksB.historyGap));
    final small = SizedBox(height: a.of(AuroraSpacing.space3));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FractionallySizedBox(
          widthFactor: AuroraTasksB.skelEyebrowFactor,
          child: LoadingSkeletonCard(
            height: a.of(AuroraTasksB.skelEyebrow),
            borderRadius: AuroraRadius.xs,
          ),
        ),
        small,
        FractionallySizedBox(
          widthFactor: AuroraTasksB.skelTitleFactor,
          child: LoadingSkeletonCard(
            height: a.of(AuroraTasksB.skelTitle),
            borderRadius: AuroraRadius.md,
          ),
        ),
        gap,
        LoadingSkeletonCard(
          height: a.of(AuroraTasksB.skelTiles),
          borderRadius: AuroraRadius.lg,
        ),
        gap,
        LoadingSkeletonCard(
          height: a.of(AuroraTasksB.stripBar),
          borderRadius: AuroraRadius.xs,
        ),
        gap,
        LoadingSkeletonCard(height: a.of(AuroraTasksB.skelBlock)),
      ],
    );
  }
}
