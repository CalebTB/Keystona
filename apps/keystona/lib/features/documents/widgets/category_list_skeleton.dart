import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';

/// Shimmer placeholder displayed while [documentCategoriesProvider] is loading.
///
/// Mirrors the layout of a category list row (40px color dot + two text lines)
/// so there is no layout jump when real content arrives.
class CategoryListSkeleton extends StatelessWidget {
  const CategoryListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.gray200,
      highlightColor: AppColors.gray100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header placeholder
          _sectionHeader(),
          ..._rows(3),
          const SizedBox(height: AppSizes.md),
          _sectionHeader(),
          ..._rows(2),
        ],
      ),
    );
  }

  Widget _sectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      child: Container(
        height: 14,
        width: 80,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
      ),
    );
  }

  List<Widget> _rows(int count) {
    return List.generate(count, (_) => const _SkeletonRow());
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      child: Row(
        children: [
          // Color dot + icon placeholder
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          // Name text placeholder
          Expanded(
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.xl),
        ],
      ),
    );
  }
}
