import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_docs_c.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/loading_skeleton_card.dart';

/// Shimmer rows while results load. Mirrors the result list card.
class SearchSkeleton extends StatelessWidget {
  const SearchSkeleton({super.key});

  /// Placeholder rows shown.
  static const int rows = 3;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: 0.3,
          child: LoadingSkeletonCard(height: a.of(AuroraSpacing.space5)),
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        for (var i = 0; i < rows; i++) ...[
          if (i > 0) SizedBox(height: a.of(AuroraSpacing.space3)),
          LoadingSkeletonCard(
            height: a.minControl(AuroraDocsCSizes.resultRowMinHeight),
          ),
        ],
      ],
    );
  }
}
