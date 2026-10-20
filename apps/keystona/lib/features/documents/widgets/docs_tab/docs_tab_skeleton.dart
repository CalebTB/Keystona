import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_a.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/loading_skeleton_card.dart';

/// First-frame placeholder that mirrors the Docs tab: header, search field,
/// expiring card, then the recent list.
class DocsTabSkeleton extends StatelessWidget {
  const DocsTabSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraSpacing.space8));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bar(
                    height: AuroraDocsA.skelEyebrow,
                    widthFactor: AuroraDocsA.skelEyebrowWidthFactor,
                  ),
                  SizedBox(height: a.of(AuroraSpacing.space2)),
                  _Bar(
                    height: AuroraDocsA.skelTitle,
                    widthFactor: AuroraDocsA.skelTitleWidthFactor,
                  ),
                  SizedBox(height: a.of(AuroraSpacing.space2)),
                  _Bar(
                    height: AuroraDocsA.skelSubtitle,
                    widthFactor: AuroraDocsA.skelSubtitleWidthFactor,
                  ),
                ],
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space5)),
            LoadingSkeletonCard(
              height: AuroraSizes.minTouch,
              width: AuroraSizes.minTouch,
              borderRadius: AuroraRadius.full,
            ),
          ],
        ),
        gap,
        LoadingSkeletonCard(
          height: a.of(AuroraSizes.minTouch),
          borderRadius: AuroraRadius.md,
        ),
        gap,
        LoadingSkeletonCard(
          height: a.of(AuroraDocsA.skelHero),
          borderRadius: AuroraRadius.banner,
        ),
        gap,
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AuroraRadius.xl,
            border: Border.all(
              color: AuroraColors.inkBorder,
              width: AuroraBorders.regular,
            ),
          ),
          child: Column(
            children: [
              for (var i = 0; i < AuroraDocsA.skelRowCount; i++)
                Padding(
                  padding: a.all(AuroraSpacing.space3),
                  child: LoadingSkeletonCard(
                    height:
                        a.of(AuroraDocsA.skelRow) - a.of(AuroraSpacing.space7),
                    borderRadius: AuroraRadius.md,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.widthFactor});

  final double height;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: LoadingSkeletonCard(
        height: a.of(height),
        borderRadius: AuroraRadius.sm,
      ),
    );
  }
}
