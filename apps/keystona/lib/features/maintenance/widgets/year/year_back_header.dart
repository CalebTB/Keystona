import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_a.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../tasks_copy.dart';

/// "‹ Tasks" back link, then the eyebrow and the "All tasks" title.
class YearBackHeader extends StatelessWidget {
  const YearBackHeader({super.key, required this.eyebrow});

  final String eyebrow;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuroraPressable(
          onTap: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.maintenance),
          semanticLabel: TasksCopy.back,
          enforceTouchTarget: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chevron_left, size: a.of(AuroraIconSizes.lg)),
              Text(TasksCopy.back, style: AuroraTasksAType.back),
            ],
          ),
        ),
        SizedBox(height: a.of(AuroraSpacing.space1)),
        Text(eyebrow, style: AuroraType.label),
        SizedBox(height: a.of(AuroraSpacing.space2)),
        Text(TasksCopy.allTasksTitle, style: AuroraType.h1),
      ],
    );
  }
}
