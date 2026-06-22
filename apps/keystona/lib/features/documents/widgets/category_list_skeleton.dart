import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';

/// Shimmer placeholder displayed while [documentCategoriesProvider] is loading.
///
/// Mirrors the layout of a category list row (40px color dot + two text lines)
/// so there is no layout jump when real content arrives.
class CategoryListSkeleton extends StatelessWidget {
  const CategoryListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AuroraColors.butter,
      highlightColor: AuroraColors.paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header placeholder
          _sectionHeader(),
          ..._rows(3),
          const SizedBox(height: AuroraSpacing.space5),
          _sectionHeader(),
          ..._rows(2),
        ],
      ),
    );
  }

  Widget _sectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.space5,
        vertical: AuroraSpacing.space3,
      ),
      child: Container(
        height: 14,
        width: 80,
        decoration: const BoxDecoration(
          color: AuroraColors.paper,
          borderRadius: AuroraRadius.sm,
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
        horizontal: AuroraSpacing.space5,
        vertical: AuroraSpacing.space3,
      ),
      child: Row(
        children: [
          // Color dot + icon placeholder
          const SizedBox(
            width: 40,
            height: 40,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AuroraColors.paper,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: AuroraSpacing.space5),
          // Name text placeholder
          Expanded(
            child: Container(
              height: 14,
              decoration: const BoxDecoration(
                color: AuroraColors.paper,
                borderRadius: AuroraRadius.sm,
              ),
            ),
          ),
          const SizedBox(width: AuroraSpacing.space8),
        ],
      ),
    );
  }
}
