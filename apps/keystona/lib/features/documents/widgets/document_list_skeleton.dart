import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';

/// Shimmer loading placeholder that matches the [DocumentCard] layout exactly.
///
/// Displayed on the first frame while [DocumentsNotifier] resolves so the
/// screen is never blank. Shows 4 skeleton cards in a scrollable list.
class DocumentListSkeleton extends StatelessWidget {
  const DocumentListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.gray200,
      highlightColor: AppColors.gray100,
      child: ListView.separated(
        padding: AppPadding.screen,
        itemCount: 4,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSizes.sm),
        itemBuilder: (context, index) => const _SkeletonCard(),
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
          // Thumbnail placeholder — matches the 48×48 thumb in DocumentCard.
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              borderRadius: AppRadius.sm,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          // Text lines — title, category chip, date.
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
        ],
      ),
    );
  }
}
