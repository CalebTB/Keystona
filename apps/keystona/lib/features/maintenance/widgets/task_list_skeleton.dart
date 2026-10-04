import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_radius.dart';

/// Shimmer loading placeholder that matches the [TaskCard] layout exactly.
///
/// Displayed on the first frame while [MaintenanceTasksNotifier] resolves.
/// Shows a section header followed by 3 skeleton cards.
class TaskListSkeleton extends StatelessWidget {
  const TaskListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AuroraColors.butter,
      highlightColor: AuroraColors.paper,
      child: ListView(
        padding: const EdgeInsets.all(AuroraSpacing.screenPadH),
        children: [
          // Section header placeholder.
          Container(
            height: 14,
            width: 100,
            margin: const EdgeInsets.only(bottom: AuroraSpacing.space3),
            color: AuroraColors.butter,
          ),
          const SizedBox(height: AuroraSpacing.space1),
          const _SkeletonCard(),
          const SizedBox(height: AuroraSpacing.space3),
          const _SkeletonCard(),
          const SizedBox(height: AuroraSpacing.space3),
          const _SkeletonCard(),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: AuroraRadius.md,
      ),
      child: Row(
        children: [
          // Priority stripe placeholder — matches the 4px left border on TaskCard.
          Container(
            width: 4,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AuroraColors.butter,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AuroraSpacing.space5),
          // Text column — name, category, due date.
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: double.infinity, color: AuroraColors.butter),
                const SizedBox(height: 6),
                Container(height: 11, width: 120, color: AuroraColors.butter),
                const SizedBox(height: 6),
                Container(height: 11, width: 80, color: AuroraColors.butter),
              ],
            ),
          ),
          const SizedBox(width: AuroraSpacing.space3),
          // Due date badge placeholder.
          Container(
            width: 60,
            height: 28,
            decoration: BoxDecoration(
              color: AuroraColors.butter,
              borderRadius: AuroraRadius.sm,
            ),
          ),
        ],
      ),
    );
  }
}
