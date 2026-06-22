import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/aurora_colors.dart';

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
      baseColor: AuroraColors.butter,
      highlightColor: AuroraColors.paper,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Badge chips row — status, priority, difficulty.
            Row(
              children: [
                _SkeletonChip(width: 80),
                const SizedBox(width: 8),
                _SkeletonChip(width: 64),
                const SizedBox(width: 8),
                _SkeletonChip(width: 56),
              ],
            ),

            const SizedBox(height: 16),

            // Due date + recurrence rows.
            _SkeletonRow(labelWidth: 48, valueWidth: 120),
            const SizedBox(height: 12),
            _SkeletonRow(labelWidth: 64, valueWidth: 96),

            const SizedBox(height: 16),
            const _SkeletonDivider(),
            const SizedBox(height: 16),

            // Description section.
            _SkeletonSectionHeader(width: 80),
            const SizedBox(height: 8),
            _SkeletonLine(width: double.infinity),
            const SizedBox(height: 4),
            _SkeletonLine(width: 220),

            const SizedBox(height: 16),
            const _SkeletonDivider(),
            const SizedBox(height: 16),

            // Instructions section.
            _SkeletonSectionHeader(width: 96),
            const SizedBox(height: 8),
            _SkeletonLine(width: double.infinity),
            const SizedBox(height: 4),
            _SkeletonLine(width: double.infinity),
            const SizedBox(height: 4),
            _SkeletonLine(width: 160),

            const SizedBox(height: 16),
            const _SkeletonDivider(),
            const SizedBox(height: 16),

            // Tools section.
            _SkeletonSectionHeader(width: 88),
            const SizedBox(height: 8),
            _SkeletonLine(width: 112),
            const SizedBox(height: 4),
            _SkeletonLine(width: 88),

            const SizedBox(height: 16),
            const _SkeletonDivider(),
            const SizedBox(height: 16),

            // Completion history header.
            _SkeletonSectionHeader(width: 128),
            const SizedBox(height: 12),

            // Two history rows.
            const _SkeletonCompletionRow(),
            const SizedBox(height: 8),
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
        color: AuroraColors.butter,
        borderRadius: BorderRadius.circular(8),
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
        Container(width: 16, height: 16, color: AuroraColors.butter),
        const SizedBox(width: 8),
        Container(width: valueWidth, height: 14, color: AuroraColors.butter),
      ],
    );
  }
}

class _SkeletonSectionHeader extends StatelessWidget {
  const _SkeletonSectionHeader({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(width: width, height: 13, color: AuroraColors.butter);
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(width: width, height: 14, color: AuroraColors.butter);
  }
}

class _SkeletonDivider extends StatelessWidget {
  const _SkeletonDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AuroraColors.inkBorder);
  }
}

class _SkeletonCompletionRow extends StatelessWidget {
  const _SkeletonCompletionRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: AuroraColors.inkBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 96, height: 13, color: AuroraColors.butter),
                const SizedBox(height: 4),
                Container(width: 64, height: 12, color: AuroraColors.butter),
              ],
            ),
          ),
          Container(width: 56, height: 13, color: AuroraColors.butter),
        ],
      ),
    );
  }
}
