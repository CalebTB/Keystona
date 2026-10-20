import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_home_a.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/loading_skeleton_card.dart';

/// Placeholder shaped like the profile: cover, title lines, the callout, the
/// systems rows and the five-year card.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraSpacing.space9));
    final tight = SizedBox(height: a.of(AuroraSpacing.space3));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AspectRatio(
          aspectRatio: AuroraHomeASizes.coverAspect,
          child: LoadingSkeletonCard(height: double.infinity),
        ),
        tight,
        LoadingSkeletonCard(height: a.of(AuroraHomeASizes.skelLine)),
        tight,
        LoadingSkeletonCard(height: a.of(AuroraHomeASizes.skelTitle)),
        gap,
        LoadingSkeletonCard(height: a.of(AuroraHomeASizes.skelCallout)),
        gap,
        LoadingSkeletonCard(height: a.of(AuroraHomeASizes.skelRows)),
        gap,
        LoadingSkeletonCard(height: a.of(AuroraHomeASizes.skelCard)),
      ],
    );
  }
}
