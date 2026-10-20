import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_home_b.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/loading_skeleton_card.dart';

/// What the Systems list looks like while loading: the filter row and a card
/// of rows, in the real layout so nothing jumps.
class SystemsSkeleton extends StatelessWidget {
  const SystemsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoadingSkeletonCard(height: a.of(AuroraHomeBSizes.skeletonFilter)),
        SizedBox(height: a.of(AuroraSpacing.space8)),
        for (var i = 0; i < AuroraHomeBSizes.skeletonRows; i++) ...[
          LoadingSkeletonCard(height: a.of(AuroraHomeBSizes.skeletonRow)),
          SizedBox(height: a.of(AuroraSpacing.space3)),
        ],
      ],
    );
  }
}
