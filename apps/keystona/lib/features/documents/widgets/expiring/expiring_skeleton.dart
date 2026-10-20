import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_docs_c.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/loading_skeleton_card.dart';

/// Shimmer for the Expiring body: the range control and a few cards.
class ExpiringSkeleton extends StatelessWidget {
  const ExpiringSkeleton({super.key});

  /// Placeholder cards shown.
  static const int cards = 3;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoadingSkeletonCard(height: a.minControl(AuroraSizes.buttonHeight)),
        SizedBox(height: a.of(AuroraSpacing.space9)),
        for (var i = 0; i < cards; i++) ...[
          if (i > 0) SizedBox(height: a.of(AuroraSpacing.space3)),
          LoadingSkeletonCard(height: a.of(AuroraDocsCSizes.skeletonExpiringCard)),
        ],
      ],
    );
  }
}
