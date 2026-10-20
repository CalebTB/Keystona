import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../../../core/theme/aurora_typography.dart';

/// The task being logged: its name and "FURNACE · EVERY FALL · DUE OCT 28".
class TaskLogTaskCard extends StatelessWidget {
  const TaskLogTaskCard({
    super.key,
    required this.name,
    required this.meta,
    required this.icon,
  });

  final String name;

  /// Uppercased here.
  final String meta;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      padding: a.symmetric(
        horizontal: AuroraSpacing.space6,
        vertical: AuroraSpacing.space5,
      ),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.lg,
        border: Border.all(
          color: AuroraColors.inkBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: a.of(AuroraTasksB.logTile),
            height: a.of(AuroraTasksB.logTile),
            decoration: BoxDecoration(
              borderRadius: AuroraRadius.tile,
              border: Border.all(
                color: AuroraColors.inkTileBorder,
                width: AuroraBorders.regular,
              ),
            ),
            child: ExcludeSemantics(
              child: Icon(
                icon,
                size: a.of(AuroraIconSizes.md),
                color: AuroraColors.ink,
              ),
            ),
          ),
          SizedBox(width: a.of(AuroraSpacing.space5)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AuroraTasksBType.logCardTitle),
                SizedBox(height: a.of(AuroraTasksB.hairlineGap)),
                Text(meta.toUpperCase(), style: AuroraType.meta),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
