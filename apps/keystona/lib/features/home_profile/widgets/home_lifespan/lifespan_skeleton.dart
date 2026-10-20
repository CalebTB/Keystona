import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_home_a.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/loading_skeleton_card.dart';

/// Placeholder shaped like the screen: title, total, tabs, three timeline
/// rows and the set-aside card.
class LifespanSkeleton extends StatelessWidget {
  const LifespanSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraSpacing.space7));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoadingSkeletonCard(height: a.of(AuroraHomeASizes.skelLine)),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        LoadingSkeletonCard(height: a.of(AuroraHomeASizes.skelTitle)),
        gap,
        LoadingSkeletonCard(height: a.of(AuroraHomeASizes.skelTitle)),
        gap,
        LoadingSkeletonCard(height: a.of(AuroraHomeASizes.skelTabs)),
        gap,
        for (var i = 0; i < _rows; i++) ...[
          LoadingSkeletonCard(height: a.of(AuroraHomeASizes.skelTimelineRow)),
          SizedBox(height: a.of(AuroraSpacing.space3)),
        ],
        LoadingSkeletonCard(height: a.of(AuroraHomeASizes.skelCard)),
      ],
    );
  }

  /// Timeline rows drawn while loading.
  static const int _rows = 3;
}
