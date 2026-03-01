import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/maintenance_task.dart';

/// A list-item card representing a single maintenance task.
///
/// Layout:
///   [Priority stripe | Name + Category + Due date row | Status badge]
///
/// The left border color follows the task urgency:
///   - Overdue → red
///   - Due today → orange
///   - Due this week → amber
///   - Upcoming / Scheduled → navy
///   - Completed → green
///
/// Tapping the card navigates to the task detail route (#32).
class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task});

  final MaintenanceTask task;

  @override
  Widget build(BuildContext context) {
    final stripeColor = _stripeColor(task);

    return GestureDetector(
      onTap: () {
        final path = AppRoutes.maintenanceTaskDetail.replaceFirst(
          ':taskId',
          task.id,
        );
        context.push(path);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.border),
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
                  padding: AppPadding.card,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _TaskInfo(task: task),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      _DueDateBadge(task: task),
                    ],
                  ),
                ),
              ),
            ],
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

    if (task.status == TaskStatus.completed) return AppColors.statusCompleted;
    if (task.status == TaskStatus.overdue || due.isBefore(todayMidnight)) {
      return AppColors.statusOverdue;
    }
    if (!due.isBefore(todayMidnight) && due.isBefore(tomorrowMidnight)) {
      return AppColors.statusDueToday;
    }
    if (due.isBefore(weekEnd)) return AppColors.statusDueSoon;
    return AppColors.statusScheduled;
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
          style: AppTextStyles.bodyMediumSemibold,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSizes.xs),
        Row(
          children: [
            // Category label.
            Flexible(
              child: Text(
                task.category,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Linked system chip — shown when available.
            if (task.linkedSystemName != null) ...[
              const SizedBox(width: AppSizes.xs),
              const Text(
                '·',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(width: AppSizes.xs),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.home_repair_service_outlined,
                      size: 11,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        task.linkedSystemName!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
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
              const Icon(
                Icons.schedule_outlined,
                size: 11,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 2),
              Text(
                _formatMinutes(task.estimatedMinutes!),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
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
      return _Badge(label: 'Done', color: AppColors.statusCompleted);
    }

    if (due.isBefore(todayMidnight) ||
        task.status == TaskStatus.overdue) {
      final days = todayMidnight.difference(due).inDays;
      return _Badge(
        label: days == 0 ? 'Today' : '${days}d ago',
        color: AppColors.statusOverdue,
      );
    }

    final daysUntil = due.difference(todayMidnight).inDays;
    if (daysUntil == 0) {
      return _Badge(label: 'Today', color: AppColors.statusDueToday);
    }

    if (daysUntil <= 7) {
      return _Badge(
        label: DateFormat('MMM d').format(due),
        color: AppColors.statusDueSoon,
      );
    }

    return _Badge(
      label: DateFormat('MMM d').format(due),
      color: AppColors.statusScheduled,
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }
}
