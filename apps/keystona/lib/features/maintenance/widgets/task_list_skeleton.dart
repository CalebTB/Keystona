import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';

/// Shimmer loading placeholder that matches the [TaskCard] layout exactly.
///
/// Displayed on the first frame while [MaintenanceTasksNotifier] resolves.
/// Shows a section header followed by 3 skeleton cards.
class TaskListSkeleton extends StatelessWidget {
  const TaskListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.gray200,
      highlightColor: AppColors.gray100,
      child: ListView(
        padding: AppPadding.screen,
        children: [
          // Section header placeholder.
          Container(
            height: 14,
            width: 100,
            margin: const EdgeInsets.only(bottom: AppSizes.sm),
            color: AppColors.gray200,
          ),
          const SizedBox(height: AppSizes.xs),
          const _SkeletonCard(),
          const SizedBox(height: AppSizes.sm),
          const _SkeletonCard(),
          const SizedBox(height: AppSizes.sm),
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
      padding: AppPadding.card,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
      ),
      child: Row(
        children: [
          // Priority stripe placeholder — matches the 4px left border on TaskCard.
          Container(
            width: 4,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          // Text column — name, category, due date.
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  color: AppColors.gray200,
                ),
                const SizedBox(height: 6),
                Container(
                  height: 11,
                  width: 120,
                  color: AppColors.gray200,
                ),
                const SizedBox(height: 6),
                Container(
                  height: 11,
                  width: 80,
                  color: AppColors.gray200,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          // Due date badge placeholder.
          Container(
            width: 60,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
          ),
        ],
      ),
    );
  }
}
