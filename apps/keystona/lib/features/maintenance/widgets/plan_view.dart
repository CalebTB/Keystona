import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/maintenance_task.dart';
import '../providers/maintenance_tasks_provider.dart';

// ── Month helpers ──────────────────────────────────────────────────────────────

/// Returns the first day of [month] months ahead of today (0 = current month).
DateTime _monthStart(int offset) {
  final now = DateTime.now();
  return DateTime(now.year, now.month + offset, 1);
}

bool _sameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

Color _priorityDot(TaskPriority p) => switch (p) {
      TaskPriority.critical => AppColors.accent,
      TaskPriority.high => AppColors.sandAmber,
      TaskPriority.medium => AppColors.slate,
      TaskPriority.low => AppColors.gray400,
    };

// ── Main sliver widget ─────────────────────────────────────────────────────────

class PlanViewSliver extends ConsumerStatefulWidget {
  const PlanViewSliver({super.key});

  @override
  ConsumerState<PlanViewSliver> createState() => _PlanViewSliverState();
}

class _PlanViewSliverState extends ConsumerState<PlanViewSliver> {
  // Index into the 12-month window (0 = this month).
  int _selectedMonthOffset = 0;
  final _monthScrollController = ScrollController();

  @override
  void dispose() {
    _monthScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(maintenanceTasksProvider);

    if (tasksAsync.isLoading) {
      return SliverToBoxAdapter(child: _PlanSkeleton());
    }

    final allTasks = tasksAsync.value ?? [];
    final selectedMonth = _monthStart(_selectedMonthOffset);

    // Active tasks only (not completed/skipped), due in the selected month.
    final monthTasks = allTasks
        .where((t) =>
            t.status != TaskStatus.completed &&
            t.status != TaskStatus.skipped &&
            _sameMonth(t.dueDate.toLocal(), selectedMonth))
        .toList()
      ..sort((a, b) {
        // Overdue first within the month, then by priority, then by date.
        final aOver = isTaskOverdue(a);
        final bOver = isTaskOverdue(b);
        if (aOver && !bOver) return -1;
        if (bOver && !aOver) return 1;
        final priComp =
            b.priority.sortOrder.compareTo(a.priority.sortOrder);
        if (priComp != 0) return priComp;
        return a.dueDate.compareTo(b.dueDate);
      });

    // Dot counts per month for the strip indicators.
    final Map<int, int> monthCounts = {};
    for (int i = 0; i < 12; i++) {
      final m = _monthStart(i);
      monthCounts[i] = allTasks
          .where((t) =>
              t.status != TaskStatus.completed &&
              t.status != TaskStatus.skipped &&
              _sameMonth(t.dueDate.toLocal(), m))
          .length;
    }

    final totalForMonth = monthTasks.length;
    final overdueInMonth = monthTasks.where(isTaskOverdue).length;

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month strip
          const SizedBox(height: AppSizes.md),
          SizedBox(
            height: 72,
            child: ListView.separated(
              controller: _monthScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenPadding),
              itemCount: 12,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSizes.xs),
              itemBuilder: (_, i) {
                final m = _monthStart(i);
                final selected = i == _selectedMonthOffset;
                final count = monthCounts[i] ?? 0;
                return _MonthChip(
                  month: m,
                  taskCount: count,
                  selected: selected,
                  onTap: () => setState(() => _selectedMonthOffset = i),
                );
              },
            ),
          ),
          const SizedBox(height: AppSizes.md),
          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenPadding),
            child: Row(
              children: [
                Text(
                  DateFormat('MMMM').format(selectedMonth).toUpperCase(),
                  style: AppTextStyles.monoSection,
                ),
                const SizedBox(width: AppSizes.sm),
                Text(
                  '$totalForMonth task${totalForMonth == 1 ? '' : 's'}',
                  style: AppTextStyles.monoSection
                      .copyWith(color: AppColors.textSecondary),
                ),
                if (overdueInMonth > 0) ...[
                  const SizedBox(width: AppSizes.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusXs),
                    ),
                    child: Text(
                      '$overdueInMonth overdue',
                      style: AppTextStyles.monoSection
                          .copyWith(color: AppColors.accent),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          // Task list
          if (monthTasks.isEmpty)
            _EmptyMonthState(month: selectedMonth)
          else
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenPadding),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.card,
                  border:
                      Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < monthTasks.length; i++) ...[
                      _PlanTaskRow(
                        task: monthTasks[i],
                        onReschedule: () =>
                            _showReschedulePicker(monthTasks[i]),
                      ),
                      if (i < monthTasks.length - 1)
                        Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.warmFill,
                            indent: 38),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }

  Future<void> _showReschedulePicker(MaintenanceTask task) async {
    DateTime picked = task.dueDate.toLocal();

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Material(
        type: MaterialType.transparency,
        child: Container(
          height: 300,
          color: AppColors.surface,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md, vertical: AppSizes.sm),
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: AppColors.border, width: 1)),
                ),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true)
                              .pop(),
                      child: Text('Cancel',
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary)),
                    ),
                    const Spacer(),
                    Text('Reschedule',
                        style: AppTextStyles.bodyMediumSemibold),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () async {
                        Navigator.of(context, rootNavigator: true).pop();
                        await ref
                            .read(maintenanceTasksProvider.notifier)
                            .updateTask(task.id, {
                          'due_date': picked
                              .toIso8601String()
                              .split('T')[0],
                        });
                      },
                      child: Text('Done',
                          style: AppTextStyles.bodyMediumSemibold
                              .copyWith(color: AppColors.accent)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: picked,
                  minimumDate: DateTime(2020),
                  onDateTimeChanged: (d) => picked = d,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool isTaskOverdue(MaintenanceTask t) {
  final today = DateTime.now();
  final todayMid = DateTime(today.year, today.month, today.day);
  final due = t.dueDate.toLocal();
  final dueMid = DateTime(due.year, due.month, due.day);
  return t.status == TaskStatus.overdue || dueMid.isBefore(todayMid);
}

// ── Month chip ─────────────────────────────────────────────────────────────────

class _MonthChip extends StatelessWidget {
  const _MonthChip({
    required this.month,
    required this.taskCount,
    required this.selected,
    required this.onTap,
  });

  final DateTime month;
  final int taskCount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isPast = month.year < now.year ||
        (month.year == now.year && month.month < now.month);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 58,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.deepNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: selected
              ? null
              : Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('MMM').format(month),
              style: AppTextStyles.labelMedium.copyWith(
                color: selected
                    ? AppColors.textInverse
                    : isPast
                        ? AppColors.gray400
                        : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            if (taskCount > 0)
              Text(
                '$taskCount',
                style: AppTextStyles.monoTiny.copyWith(
                  color: selected
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              )
            else
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.darkTextTertiary
                      : AppColors.gray300,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Plan task row ──────────────────────────────────────────────────────────────

class _PlanTaskRow extends StatelessWidget {
  const _PlanTaskRow({
    required this.task,
    required this.onReschedule,
  });

  final MaintenanceTask task;
  final VoidCallback onReschedule;

  @override
  Widget build(BuildContext context) {
    final dot = _priorityDot(task.priority);
    final isOver = isTaskOverdue(task);
    final dueFmt = DateFormat('MMM d').format(task.dueDate.toLocal());

    return GestureDetector(
      onTap: () => context.push('/maintenance/${task.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isOver ? AppColors.accent : dot,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.name, style: AppTextStyles.bodyMedium),
                  Row(
                    children: [
                      Text(
                        task.category,
                        style: AppTextStyles.caption,
                      ),
                      Text(' · ', style: AppTextStyles.caption),
                      Text(
                        dueFmt,
                        style: AppTextStyles.caption.copyWith(
                          color:
                              isOver ? AppColors.accent : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onReschedule,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warmFill,
                  borderRadius: BorderRadius.circular(AppSizes.radiusXs),
                ),
                child: Text(
                  'Reschedule',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty month state ──────────────────────────────────────────────────────────

class _EmptyMonthState extends StatelessWidget {
  const _EmptyMonthState({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 28, color: AppColors.gray400),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Nothing in ${DateFormat('MMMM').format(month)}',
              style: AppTextStyles.bodyMediumSemibold,
            ),
            const SizedBox(height: 4),
            Text(
              'No tasks due this month.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton ───────────────────────────────────────────────────────────────────

class _PlanSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.gray200,
      highlightColor: AppColors.gray100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.md),
          SizedBox(
            height: 72,
            child: Row(
              children: [
                const SizedBox(width: AppSizes.screenPadding),
                for (int i = 0; i < 5; i++) ...[
                  Container(
                    width: 58,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.gray200,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                  if (i < 4) const SizedBox(width: AppSizes.xs),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenPadding),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: AppRadius.card,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
