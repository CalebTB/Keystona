import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_home_a.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/loading_skeleton_card.dart';

/// Placeholder shaped like the form: the photo row, then fields.
class EditSkeleton extends StatelessWidget {
  const EditSkeleton({super.key});

  /// Field blocks drawn while loading.
  static const int _fields = 5;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraSpacing.space6));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoadingSkeletonCard(height: a.of(AuroraHomeASizes.skelCard)),
        for (var i = 0; i < _fields; i++) ...[
          gap,
          LoadingSkeletonCard(height: a.of(AuroraHomeASizes.skelField)),
        ],
      ],
    );
  }
}
