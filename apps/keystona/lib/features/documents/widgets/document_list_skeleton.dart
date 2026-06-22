import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';

/// Shimmer loading placeholder that matches the [DocumentCard] layout exactly.
///
/// Displayed on the first frame while [DocumentsNotifier] resolves so the
/// screen is never blank. Shows 4 skeleton cards in a scrollable list.
class DocumentListSkeleton extends StatelessWidget {
  const DocumentListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AuroraColors.butter,
      highlightColor: AuroraColors.paper,
      child: ListView.separated(
        padding: const EdgeInsets.all(AuroraSpacing.screenPadH),
        itemCount: 4,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AuroraSpacing.space3),
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
      padding: const EdgeInsets.all(AuroraSpacing.space6),
      decoration: const BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: AuroraRadius.md,
      ),
      child: Row(
        children: [
          // Thumbnail placeholder — matches the 48×48 thumb in DocumentCard.
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AuroraColors.butter,
              borderRadius: AuroraRadius.sm,
            ),
          ),
          const SizedBox(width: AuroraSpacing.space5),
          // Text lines — title, category chip, date.
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  color: AuroraColors.butter,
                ),
                const SizedBox(height: 6),
                Container(
                  height: 11,
                  width: 120,
                  color: AuroraColors.butter,
                ),
                const SizedBox(height: 6),
                Container(
                  height: 11,
                  width: 80,
                  color: AuroraColors.butter,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
