import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';

/// Shimmer skeleton for [TaskDetailScreen].
///
/// Layout mirrors the fully-loaded screen so the skeleton → content
/// transition has no layout jump:
///   [3 badge chips]
///   [Due date row]
///   [Description section]
///   [Divider]
///   [Instructions section — 3 lines]
///   [Tools section — 2 items]
///   [Completion history header]
///   [2 history rows]
class TaskDetailSkeleton extends StatelessWidget {
  const TaskDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.gray200,
      highlightColor: AppColors.gray100,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: AppPadding.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSizes.sm),

            // Badge chips row — status, priority, difficulty.
            Row(
              children: [
                _SkeletonChip(width: 80),
                const SizedBox(width: AppSizes.sm),
                _SkeletonChip(width: 64),
                const SizedBox(width: AppSizes.sm),
                _SkeletonChip(width: 56),
              ],
            ),

            const SizedBox(height: AppSizes.lg),

            // Due date + recurrence rows.
            _SkeletonRow(labelWidth: 48, valueWidth: 120),
            const SizedBox(height: AppSizes.md),
            _SkeletonRow(labelWidth: 64, valueWidth: 96),

            const SizedBox(height: AppSizes.lg),
            const _SkeletonDivider(),
            const SizedBox(height: AppSizes.lg),

            // Description section.
            _SkeletonSectionHeader(width: 80),
            const SizedBox(height: AppSizes.sm),
            _SkeletonLine(width: double.infinity),
            const SizedBox(height: AppSizes.xs),
            _SkeletonLine(width: 220),

            const SizedBox(height: AppSizes.lg),
            const _SkeletonDivider(),
            const SizedBox(height: AppSizes.lg),

            // Instructions section.
            _SkeletonSectionHeader(width: 96),
            const SizedBox(height: AppSizes.sm),
            _SkeletonLine(width: double.infinity),
            const SizedBox(height: AppSizes.xs),
            _SkeletonLine(width: double.infinity),
            const SizedBox(height: AppSizes.xs),
            _SkeletonLine(width: 160),

            const SizedBox(height: AppSizes.lg),
            const _SkeletonDivider(),
            const SizedBox(height: AppSizes.lg),

            // Tools section.
            _SkeletonSectionHeader(width: 88),
            const SizedBox(height: AppSizes.sm),
            _SkeletonLine(width: 112),
            const SizedBox(height: AppSizes.xs),
            _SkeletonLine(width: 88),

            const SizedBox(height: AppSizes.lg),
            const _SkeletonDivider(),
            const SizedBox(height: AppSizes.lg),

            // Completion history header.
            _SkeletonSectionHeader(width: 128),
            const SizedBox(height: AppSizes.md),

            // Two history rows.
            const _SkeletonCompletionRow(),
            const SizedBox(height: AppSizes.sm),
            const _SkeletonCompletionRow(),

            // Space for bottom action buttons.
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}

// ── Shared skeleton sub-widgets ───────────────────────────────────────────────

class _SkeletonChip extends StatelessWidget {
  const _SkeletonChip({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.labelWidth, required this.valueWidth});
  final double labelWidth;
  final double valueWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: AppColors.gray200),
        const SizedBox(width: AppSizes.sm),
        Container(width: valueWidth, height: 14, color: AppColors.gray200),
      ],
    );
  }
}

class _SkeletonSectionHeader extends StatelessWidget {
  const _SkeletonSectionHeader({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(width: width, height: 13, color: AppColors.gray200);
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(width: width, height: 14, color: AppColors.gray200);
  }
}

class _SkeletonDivider extends StatelessWidget {
  const _SkeletonDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.divider);
  }
}

class _SkeletonCompletionRow extends StatelessWidget {
  const _SkeletonCompletionRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: AppPadding.card,
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 96, height: 13, color: AppColors.gray200),
                const SizedBox(height: AppSizes.xs),
                Container(width: 64, height: 12, color: AppColors.gray200),
              ],
            ),
          ),
          Container(width: 56, height: 13, color: AppColors.gray200),
        ],
      ),
    );
  }
}
