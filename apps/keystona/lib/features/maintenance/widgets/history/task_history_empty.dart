import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../../../core/theme/aurora_typography.dart';

/// History with nothing logged yet.
class TaskHistoryEmpty extends StatelessWidget {
  const TaskHistoryEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      padding: a.all(AuroraSpacing.space7),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.xl,
        border: Border.all(
          color: AuroraColors.inkBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nothing logged yet', style: AuroraType.h3),
          SizedBox(height: a.of(AuroraSpacing.space2)),
          Text(
            'Mark the task done, or log one you already did.',
            style: AuroraTasksBType.entryMeta,
          ),
        ],
      ),
    );
  }
}
