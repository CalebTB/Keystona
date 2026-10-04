import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_typography.dart';
import '../models/maintenance_task.dart';
import '../../../core/theme/aurora_radius.dart';

/// A list-item card representing a single maintenance task.
///
/// Layout:
///   [Priority stripe | Name + Category + Due date row | Status badge]
///
/// The left border color follows the task urgency:
///   - Overdue → coral
///   - Due today → yellowDeep
///   - Due this week → yellow
///   - Upcoming / Scheduled → cobalt
///   - Completed → limeDeep
///
/// Tapping the card navigates to the task detail route (#32).
class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task});

  final MaintenanceTask task;

  @override
  Widget build(BuildContext context) {
    final stripeColor = _stripeColor(task);

    return Material(
      color: AuroraColors.paper,
      borderRadius: AuroraRadius.lg,
      child: InkWell(
        onTap: () {
          final path = AppRoutes.maintenanceTaskDetail.replaceFirst(
            ':taskId',
            task.id,
          );
          context.push(path);
        },
        borderRadius: AuroraRadius.lg,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AuroraRadius.lg,
            border: Border.all(color: AuroraColors.inkBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0x0D071238),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Priority urgency stripe.
                Container(
                  width: 4,
                  color: stripeColor,
                ),
                // Content.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _TaskInfo(task: task),
                        ),
                        const SizedBox(width: 8),
                        _DueDateBadge(task: task),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _stripeColor(MaintenanceTask task) {
    final now = DateTime.now().toLocal();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final tomorrowMidnight = todayMidnight.add(const Duration(days: 1));
    final weekEnd = todayMidnight.add(const Duration(days: 7));
    final due = task.dueDate.toLocal();

    if (task.status == TaskStatus.completed) return AuroraColors.limeDeep;
    if (task.status == TaskStatus.overdue || due.isBefore(todayMidnight)) {
      return AuroraColors.coral;
    }
    if (!due.isBefore(todayMidnight) && due.isBefore(tomorrowMidnight)) {
      return AuroraColors.yellowDeep;
    }
    if (due.isBefore(weekEnd)) return AuroraColors.yellow;
    return AuroraColors.cobalt;
  }
}

// ── Task info column ──────────────────────────────────────────────────────────

class _TaskInfo extends StatelessWidget {
  const _TaskInfo({required this.task});

  final MaintenanceTask task;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          task.name,
          style: AuroraType.body.copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            // Category label.
            Flexible(
              child: Text(
                task.category,
                style: AuroraType.bodySm.copyWith(
                  color: AuroraColors.inkSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Linked system chip — shown when available.
            if (task.linkedSystemName != null) ...[
              const SizedBox(width: 4),
              Text(
                '·',
                style: AuroraType.bodySm.copyWith(color: AuroraColors.inkSecondary),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.home_repair_service_outlined,
                      size: 11,
                      color: AuroraColors.inkSecondary,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        task.linkedSystemName!,
                        style: AuroraType.bodySm.copyWith(
                          color: AuroraColors.inkSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        // Estimated time — shown when available.
        if (task.estimatedMinutes != null) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule_outlined,
                size: 11,
                color: AuroraColors.inkSecondary,
              ),
              const SizedBox(width: 2),
              Text(
                _formatMinutes(task.estimatedMinutes!),
                style: AuroraType.bodySm.copyWith(
                  color: AuroraColors.inkSecondary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    return rem == 0 ? '${hours}h' : '${hours}h ${rem}min';
  }
}

// ── Due date badge ────────────────────────────────────────────────────────────

class _DueDateBadge extends StatelessWidget {
  const _DueDateBadge({required this.task});

  final MaintenanceTask task;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toLocal();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final due = task.dueDate.toLocal();

    if (task.status == TaskStatus.completed) {
      return _Badge(label: 'Done', color: AuroraColors.limeDeep);
    }

    if (due.isBefore(todayMidnight) ||
        task.status == TaskStatus.overdue) {
      final days = todayMidnight.difference(due).inDays;
      return _Badge(
        label: days == 0 ? 'Today' : '${days}d ago',
        color: AuroraColors.coral,
      );
    }

    final daysUntil = due.difference(todayMidnight).inDays;
    if (daysUntil == 0) {
      return _Badge(label: 'Today', color: AuroraColors.yellowDeep);
    }

    if (daysUntil <= 7) {
      return _Badge(
        label: DateFormat('MMM d').format(due),
        color: AuroraColors.yellow,
      );
    }

    return _Badge(
      label: DateFormat('MMM d').format(due),
      color: AuroraColors.cobalt,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: AuroraRadius.sm,
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: AuroraType.labelSm.copyWith(color: color),
      ),
    );
  }
}
