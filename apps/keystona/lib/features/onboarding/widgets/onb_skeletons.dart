import 'package:flutter/material.dart';

import '../../../core/theme/aurora_onboarding.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/widgets/loading_skeleton_card.dart';

/// Title and subtitle placeholders.
class OnbHeaderSkeleton extends StatelessWidget {
  const OnbHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: a.of(AuroraSpacing.space3),
      children: [
        FractionallySizedBox(
          widthFactor: AuroraOnbSizes.skeletonTitleFraction,
          child: LoadingSkeletonCard(
            height: a.of(AuroraOnbSizes.skeletonTitleHeight),
          ),
        ),
        FractionallySizedBox(
          widthFactor: AuroraOnbSizes.skeletonLineFraction,
          child: LoadingSkeletonCard(
            height: a.of(AuroraOnbSizes.skeletonLineHeight),
          ),
        ),
      ],
    );
  }
}

/// Stack of card placeholders sized like the persona cards.
class OnbCardsSkeleton extends StatelessWidget {
  const OnbCardsSkeleton({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      spacing: a.of(AuroraSpacing.space5),
      children: [
        for (var i = 0; i < count; i++)
          LoadingSkeletonCard(height: a.of(AuroraOnbSizes.skeletonCardHeight)),
      ],
    );
  }
}
