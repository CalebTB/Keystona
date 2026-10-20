import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_docs_a.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/loading_skeleton_card.dart';

/// First-frame placeholder for "Your categories": the list card, the new
/// category row and the standard disclosure.
class CategoriesSkeleton extends StatelessWidget {
  const CategoriesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < AuroraDocsA.skelCategoryCount; i++) ...[
          LoadingSkeletonCard(
            height: a.of(AuroraDocsA.skelCategoryRow),
            borderRadius: AuroraRadius.md,
          ),
          if (i < AuroraDocsA.skelCategoryCount - 1)
            SizedBox(height: a.of(AuroraSpacing.space3)),
        ],
        SizedBox(height: a.of(AuroraSpacing.space9)),
        LoadingSkeletonCard(
          height: a.minControl(AuroraDocsA.disclosureMinHeight),
          borderRadius: AuroraRadius.md,
        ),
      ],
    );
  }
}
