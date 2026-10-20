import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../models/task_log_draft.dart';
import '../../services/task_format.dart';

/// The pro who did the work, from Who to call. Tapping it (the "Change"
/// link) opens the picker; with nobody chosen yet it invites the choice.
class TaskLogProCard extends StatelessWidget {
  const TaskLogProCard({super.key, required this.pro, required this.onTap});

  final TaskPro? pro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final chosen = pro;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: chosen == null ? 'Choose who did it' : 'Change who did it',
      child: Container(
        padding: a.symmetric(
          horizontal: AuroraSpacing.space6,
          vertical: AuroraSpacing.space4,
        ),
        decoration: BoxDecoration(
          borderRadius: AuroraRadius.lg,
          border: Border.all(
            color: AuroraColors.cobalt,
            width: AuroraBorders.emphasis,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: a.of(AuroraTasksB.proAvatar),
              height: a.of(AuroraTasksB.proAvatar),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AuroraColors.inkTileBorder,
                  width: AuroraBorders.regular,
                ),
              ),
              child: chosen == null
                  ? Icon(
                      Icons.person_outline,
                      size: a.of(AuroraIconSizes.md),
                      color: AuroraColors.ink,
                    )
                  : Text(
                      TaskFormat.initials(chosen.display),
                      style: AuroraTasksBType.initials,
                    ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space5)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chosen?.display ?? 'Choose a pro',
                    style: AuroraTasksBType.itemTitle,
                  ),
                  SizedBox(height: a.of(AuroraTasksB.hairlineGap)),
                  Text(
                    'From Who to call'.toUpperCase(),
                    style: AuroraType.meta,
                  ),
                ],
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space3)),
            Text(
              chosen == null ? 'Choose' : 'Change',
              style: AuroraTasksBType.change,
            ),
          ],
        ),
      ),
    );
  }
}
