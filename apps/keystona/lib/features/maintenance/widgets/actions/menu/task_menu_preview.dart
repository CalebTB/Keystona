import 'package:flutter/material.dart';

import '../../../../../core/theme/aurora_colors.dart';
import '../../../../../core/theme/aurora_radius.dart';
import '../../../../../core/theme/aurora_scale.dart';
import '../../../../../core/theme/aurora_shadows.dart';
import '../../../../../core/theme/aurora_sizes.dart';
import '../../../../../core/theme/aurora_spacing.dart';
import '../../../../../core/theme/aurora_tasks_a.dart';
import '../../../../../core/theme/aurora_typography.dart';
import '../../../../../core/widgets/aurora/aurora_chip.dart';
import '../../../models/maintenance_task.dart';
import '../../../models/task_schedule.dart';
import '../../../tasks_copy.dart';

/// The pressed task, lifted above the blurred screen at a slight scale.
class TaskMenuPreview extends StatelessWidget {
  const TaskMenuPreview({super.key, required this.task, required this.today});

  final MaintenanceTask task;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final overdue = TaskSchedule.isOverdue(task, today);
    final days = TaskSchedule.daysUntil(task, today);
    final chip = overdue
        ? StatusChip.overdue(
            label: TasksCopy.overdueBadge(TaskSchedule.daysLate(task, today)),
          )
        : days <= 7
        ? StatusChip.dueSoon(label: TasksCopy.dueBadge(days))
        : StatusChip.scheduled(label: TasksCopy.dueBadge(days));

    return Transform.scale(
      scale: AuroraTasksA.liftScale,
      child: Container(
        padding: a.all(AuroraSpacing.space7),
        decoration: BoxDecoration(
          color: AuroraColors.paper,
          borderRadius: AuroraRadius.banner,
          boxShadow: AuroraShadows.modal,
          border: Border.all(
            color: overdue ? AuroraColors.coral : AuroraColors.inkBorder,
            width: AuroraBorders.emphasis,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Tile(),
                Flexible(child: chip),
              ],
            ),
            SizedBox(height: a.of(AuroraSpacing.space4)),
            Text(task.name, style: AuroraTasksAType.previewTitle),
            if (task.description != null && task.description!.isNotEmpty) ...[
              SizedBox(height: a.of(AuroraSpacing.space4)),
              Text(
                task.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AuroraTasksAType.previewBody,
              ),
            ],
            SizedBox(height: a.of(AuroraSpacing.space4)),
            Text(
              TasksCopy.previewMeta(task),
              style: AuroraType.meta.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      width: a.of(AuroraSharedSizes.iconTile),
      height: a.of(AuroraSharedSizes.iconTile),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.md,
        border: Border.all(
          color: AuroraColors.inkTileBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Icon(
        Icons.home_outlined,
        size: a.of(AuroraIconSizes.md),
        color: AuroraColors.ink,
      ),
    );
  }
}
