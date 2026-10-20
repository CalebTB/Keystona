import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_home_b.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/loading_skeleton_card.dart';

/// The detail screen while loading: the hero and cards in their real places.
class SystemDetailSkeleton extends StatelessWidget {
  const SystemDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoadingSkeletonCard(height: a.of(AuroraHomeBSizes.skeletonField)),
        SizedBox(height: a.of(AuroraSpacing.space8)),
        LoadingSkeletonCard(height: a.of(AuroraHomeBSizes.skeletonHero)),
        SizedBox(height: a.of(AuroraSpacing.space8)),
        LoadingSkeletonCard(height: a.of(AuroraHomeBSizes.skeletonCard)),
        SizedBox(height: a.of(AuroraSpacing.space8)),
        LoadingSkeletonCard(height: a.of(AuroraHomeBSizes.skeletonCard)),
      ],
    );
  }
}
