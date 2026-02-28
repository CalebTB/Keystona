import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';

/// Skeleton loading state for [DocumentDetailScreen].
///
/// Mirrors the layout of the fully-loaded screen so the transition from
/// skeleton → content has no layout jump.
///
/// Layout mirrors:
///   [Preview area — 240px]
///   [Action buttons — 3 x 56px pills]
///   [Metadata section — 6 rows of label + value]
class DocumentDetailSkeleton extends StatelessWidget {
  const DocumentDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.gray200,
      highlightColor: AppColors.gray100,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview area placeholder.
            Container(
              width: double.infinity,
              height: 240,
              color: AppColors.gray300,
            ),

            Padding(
              padding: AppPadding.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSizes.lg),

                  // Action buttons row.
                  Row(
                    children: [
                      _SkeletonPill(width: 88),
                      const SizedBox(width: AppSizes.sm),
                      _SkeletonPill(width: 88),
                      const SizedBox(width: AppSizes.sm),
                      _SkeletonPill(width: 88),
                    ],
                  ),

                  const SizedBox(height: AppSizes.lg),
                  const _SectionDivider(),

                  // Metadata rows — 6 rows of label + value.
                  ...[96.0, 80.0, 120.0, 64.0, 100.0, 80.0].map(
                    (valueWidth) => _MetadataRowSkeleton(valueWidth: valueWidth),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonPill extends StatelessWidget {
  const _SkeletonPill({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.gray300,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
    );
  }
}

class _MetadataRowSkeleton extends StatelessWidget {
  const _MetadataRowSkeleton({required this.valueWidth});

  final double valueWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Label.
          Container(
            width: 72,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.gray300,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
          ),
          // Value.
          Container(
            width: valueWidth,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.gray300,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppColors.divider);
  }
}
