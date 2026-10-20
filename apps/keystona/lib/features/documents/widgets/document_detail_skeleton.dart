import 'package:flutter/material.dart';

import '../../../core/theme/aurora_docs_c.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_sizes.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/widgets/loading_skeleton_card.dart';

/// Shimmer placeholder that mirrors the detail screen: header, preview, a
/// coverage card and two fact cards.
class DocumentDetailSkeleton extends StatelessWidget {
  const DocumentDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraDocsCSizes.sectionGap));
    final small = SizedBox(height: a.of(AuroraSpacing.space3));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FractionallySizedBox(
          widthFactor: 0.4,
          child: LoadingSkeletonCard(
            height: a.of(AuroraIconSizes.xl),
            borderRadius: AuroraRadius.full,
          ),
        ),
        small,
        FractionallySizedBox(
          widthFactor: 0.8,
          child: LoadingSkeletonCard(
            height: a.of(AuroraSizes.buttonHeightSm),
            borderRadius: AuroraRadius.md,
          ),
        ),
        small,
        FractionallySizedBox(
          widthFactor: 0.6,
          child: LoadingSkeletonCard(
            height: a.of(AuroraIconSizes.sm),
            borderRadius: AuroraRadius.xs,
          ),
        ),
        gap,
        AspectRatio(
          aspectRatio: AuroraDocsCSizes.previewAspect,
          child: const LoadingSkeletonCard(height: double.infinity),
        ),
        gap,
        LoadingSkeletonCard(height: a.of(AuroraDocsCSizes.skeletonCard)),
        gap,
        LoadingSkeletonCard(height: a.of(AuroraDocsCSizes.skeletonCardTall)),
        gap,
        LoadingSkeletonCard(height: a.of(AuroraDocsCSizes.skeletonCard)),
      ],
    );
  }
}
