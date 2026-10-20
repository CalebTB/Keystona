import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_c.dart';
import '../../../../core/widgets/loading_skeleton_card.dart';

/// Placeholder shaped like the form while the home and its items load.
class TaskFormSkeleton extends StatelessWidget {
  const TaskFormSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraSpacing.space8));
    Widget field() =>
        LoadingSkeletonCard(height: a.of(AuroraSizes.inputHeight));
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        a.of(AuroraSpacing.screenPadH),
        a.of(AuroraTasksCSizes.formPadTop),
        a.of(AuroraSpacing.screenPadH),
        a.of(AuroraTasksCSizes.formPadBottom),
      ),
      child: Column(
        children: [
          field(),
          gap,
          field(),
          gap,
          field(),
          gap,
          LoadingSkeletonCard(height: a.of(AuroraTasksCSizes.dueChipMinHeight)),
          gap,
          field(),
        ],
      ),
    );
  }
}
