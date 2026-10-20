import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../../../core/widgets/loading_skeleton_card.dart';

/// Shimmer placeholder that mirrors the Log form: the task card, two fields,
/// the who chips and a few more blocks.
class TaskLogSkeleton extends StatelessWidget {
  const TaskLogSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraSpacing.space8));
    final field = a.of(AuroraSizes.inputHeight);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoadingSkeletonCard(
          height: a.of(AuroraTasksB.skelRow),
          borderRadius: AuroraRadius.lg,
        ),
        gap,
        Row(
          children: [
            Expanded(
              child: LoadingSkeletonCard(
                height: field,
                borderRadius: AuroraRadius.md,
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space3)),
            Expanded(
              child: LoadingSkeletonCard(
                height: field,
                borderRadius: AuroraRadius.md,
              ),
            ),
          ],
        ),
        gap,
        FractionallySizedBox(
          widthFactor: AuroraTasksB.skelTitleFactor,
          child: LoadingSkeletonCard(
            height: a.of(AuroraSizes.chipHeight),
            borderRadius: AuroraRadius.full,
          ),
        ),
        gap,
        LoadingSkeletonCard(height: a.of(AuroraTasksB.skelBlock)),
      ],
    );
  }
}
