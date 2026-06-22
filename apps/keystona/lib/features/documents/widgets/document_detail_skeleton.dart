import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';

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
      baseColor: AuroraColors.butter,
      highlightColor: AuroraColors.paper,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview area placeholder.
            Container(
              width: double.infinity,
              height: 240,
              color: AuroraColors.inkBorder,
            ),

            Padding(
              padding: const EdgeInsets.all(AuroraSpacing.screenPadH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AuroraSpacing.space7),

                  // Action buttons row.
                  Row(
                    children: [
                      _SkeletonPill(width: 88),
                      const SizedBox(width: AuroraSpacing.space3),
                      _SkeletonPill(width: 88),
                      const SizedBox(width: AuroraSpacing.space3),
                      _SkeletonPill(width: 88),
                    ],
                  ),

                  const SizedBox(height: AuroraSpacing.space7),
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
      decoration: const BoxDecoration(
        color: AuroraColors.inkBorder,
        borderRadius: AuroraRadius.md,
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
      padding: const EdgeInsets.symmetric(vertical: AuroraSpacing.space5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Label.
          Container(
            width: 72,
            height: 14,
            decoration: const BoxDecoration(
              color: AuroraColors.inkBorder,
              borderRadius: AuroraRadius.sm,
            ),
          ),
          // Value.
          Container(
            width: valueWidth,
            height: 14,
            decoration: const BoxDecoration(
              color: AuroraColors.inkBorder,
              borderRadius: AuroraRadius.sm,
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
    return const Divider(height: 1, thickness: 1, color: AuroraColors.inkBorder);
  }
}
