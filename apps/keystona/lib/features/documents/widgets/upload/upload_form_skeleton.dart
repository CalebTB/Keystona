import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_docs_b.dart';
import '../../../../core/widgets/loading_skeleton_card.dart';

/// Placeholder shaped like the form while categories load.
class UploadFormSkeleton extends StatelessWidget {
  const UploadFormSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraSpacing.space8));
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: a.symmetric(
        horizontal: AuroraSpacing.screenPadH,
        vertical: AuroraSpacing.space8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LoadingSkeletonCard(height: a.of(AuroraUploadSizes.fileThumbHeight)),
          gap,
          LoadingSkeletonCard(height: a.of(AuroraSizes.inputHeight)),
          gap,
          LoadingSkeletonCard(height: a.of(AuroraSizes.inputHeight)),
          gap,
          LoadingSkeletonCard(height: a.of(AuroraSizes.inputHeight)),
        ],
      ),
    );
  }
}
