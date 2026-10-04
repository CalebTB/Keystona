import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_typography.dart';
import '../models/maintenance_task.dart';
import '../../../core/theme/aurora_radius.dart';

/// Compact overdue strip shown below the day header when overdue tasks exist.
///
/// Replaced the tall card with a slim 1-line strip to reduce visual interruption
/// while keeping the count and task names visible.
class OverdueBanner extends StatelessWidget {
  const OverdueBanner({super.key, required this.overdueTasks});

  final List<MaintenanceTask> overdueTasks;

  @override
  Widget build(BuildContext context) {
    if (overdueTasks.isEmpty) return const SizedBox.shrink();

    final count = overdueTasks.length;
    final names = overdueTasks.take(3).map((t) => t.name).join(' · ');

    return GestureDetector(
      onTap: () => context.push('/maintenance/${overdueTasks.first.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AuroraColors.coralDim,
          borderRadius: AuroraRadius.sm,
          border: Border.all(color: AuroraColors.yellow.withValues(alpha: 0.125), width: 1),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 14,
              color: AuroraColors.coral,
            ),
            const SizedBox(width: 6),
            Text(
              '$count overdue',
              style: AuroraType.label.copyWith(
                color: AuroraColors.coral,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                names,
                style: AuroraType.label.copyWith(
                  color: AuroraColors.inkTertiary,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 14,
              color: AuroraColors.coral,
            ),
          ],
        ),
      ),
    );
  }
}
