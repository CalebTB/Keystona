import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';

/// Shimmer loading placeholder that matches the [ContactCard] layout exactly.
///
/// Displayed on the first frame while [ContactsListNotifier] resolves.
/// Shows 4 skeleton contact rows (avatar + name line + subtitle line + icon).
class ContactsListSkeleton extends StatelessWidget {
  const ContactsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.gray200,
      highlightColor: AppColors.gray100,
      child: ListView(
        padding: AppPadding.screen,
        children: const [
          _SkeletonContactCard(),
          SizedBox(height: AppSizes.sm),
          _SkeletonContactCard(),
          SizedBox(height: AppSizes.sm),
          _SkeletonContactCard(),
          SizedBox(height: AppSizes.sm),
          _SkeletonContactCard(),
        ],
      ),
    );
  }
}

/// Single skeleton card row — matches [ContactCard] height (60px content +
/// 16px vertical card padding = 92px total).
class _SkeletonContactCard extends StatelessWidget {
  const _SkeletonContactCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          // Circle avatar placeholder.
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.gray200,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSizes.md),

          // Name + category text column.
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name line.
                FractionallySizedBox(
                  widthFactor: 0.55,
                  child: Container(
                    height: 14,
                    color: AppColors.gray200,
                  ),
                ),
                const SizedBox(height: 6),
                // Category / company subtitle line.
                FractionallySizedBox(
                  widthFactor: 0.38,
                  child: Container(
                    height: 11,
                    color: AppColors.gray200,
                  ),
                ),
              ],
            ),
          ),

          // Favorite star placeholder.
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.gray200,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSizes.sm),

          // Phone button placeholder.
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.gray200,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
