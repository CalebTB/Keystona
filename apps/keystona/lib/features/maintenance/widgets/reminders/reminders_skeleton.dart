import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_c.dart';
import '../../../../core/widgets/loading_skeleton_card.dart';

/// Placeholder shaped like a reminder screen's body: a summary block and two
/// groups of rows.
class RemindersSkeleton extends StatelessWidget {
  const RemindersSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraSpacing.space8));
    final rowGap = SizedBox(height: a.of(AuroraSpacing.space3));
    Widget group() => Column(
      children: [
        for (var i = 0; i < 3; i++) ...[
          LoadingSkeletonCard(height: a.of(AuroraTasksCSizes.skeletonRow)),
          rowGap,
        ],
      ],
    );
    return Column(
      children: [
        LoadingSkeletonCard(height: a.of(AuroraTasksCSizes.skeletonSummary)),
        gap,
        group(),
        gap,
        group(),
      ],
    );
  }
}
