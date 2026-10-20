import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/loading_skeleton_card.dart';

/// Shimmer blocks that stand where an item screen's content will be: one per
/// entry of [heights] (token values, scaled here), [gap] apart.
class ItemSkeleton extends StatelessWidget {
  const ItemSkeleton({
    super.key,
    required this.heights,
    this.gap = AuroraSpacing.space5,
  });

  final List<double> heights;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < heights.length; i++) ...[
          if (i > 0) SizedBox(height: a.of(gap)),
          LoadingSkeletonCard(height: a.of(heights[i])),
        ],
      ],
    );
  }
}
