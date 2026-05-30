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
import '../providers/task_detail_provider.dart';

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

class PlanView extends ConsumerStatefulWidget {
  const PlanView({super.key});

  @override
  ConsumerState<PlanView> createState() => _PlanViewState();
}

class _PlanViewState extends ConsumerState<PlanView> {
  int _selectedMonthOffset = 0;
  // +1 = forward (later month), -1 = backward. Drives slide direction.
  int _slideDirection = 1;
  // Task IDs currently fading out before the DB write fires.
  final Set<String> _hidingTaskIds = {};
  final _monthScrollController = ScrollController();

  @override
  void dispose() {
    _monthScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(maintenanceTasksProvider);

    // Only show the skeleton on the very first load. After that, keep the
    // existing list visible while a refresh runs in the background so there's
    // no skeleton flash on every mutation.
    if (tasksAsync.isLoading && !tasksAsync.hasValue) {
      return _PlanSkeleton();
    }

    final allTasks = tasksAsync.value ?? [];
    final selectedMonth = _monthStart(_selectedMonthOffset);

    final monthTasks = allTasks
        .where((t) =>
            t.status != TaskStatus.completed &&
            t.status != TaskStatus.skipped &&
            _sameMonth(t.dueDate.toLocal(), selectedMonth))
        .toList()
      ..sort((a, b) {
        final aOver = isTaskOverdue(a);
        final bOver = isTaskOverdue(b);
        if (aOver && !bOver) return -1;
        if (bOver && !aOver) return 1;
        final priComp = b.priority.sortOrder.compareTo(a.priority.sortOrder);
        if (priComp != 0) return priComp;
        return a.dueDate.compareTo(b.dueDate);
      });

    final Map<int, int> monthCounts = {};
    final Map<int, int> monthOverdueCounts = {};
    for (int i = 0; i < 12; i++) {
      final m = _monthStart(i);
      final list = allTasks
          .where((t) =>
              t.status != TaskStatus.completed &&
              t.status != TaskStatus.skipped &&
              _sameMonth(t.dueDate.toLocal(), m))
          .toList();
      monthCounts[i] = list.length;
      monthOverdueCounts[i] = list.where(isTaskOverdue).length;
    }

    final totalForMonth = monthTasks.length;
    final overdueInMonth = monthTasks.where(isTaskOverdue).length;

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Month strip ──────────────────────────────────────────────────
          const SizedBox(height: AppSizes.md),
          SizedBox(
            height: 72,
            child: ListView.separated(
              controller: _monthScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenPadding),
              itemCount: 12,
              separatorBuilder: (_, _) => const SizedBox(width: AppSizes.xs),
              itemBuilder: (_, i) {
                final m = _monthStart(i);
                final selected = i == _selectedMonthOffset;
                final count = monthCounts[i] ?? 0;
                final overdueCount = monthOverdueCounts[i] ?? 0;
                return Opacity(
                  opacity: count == 0 ? 0.5 : 1.0,
                  child: _MonthChip(
                    month: m,
                    taskCount: count,
                    overdueCount: overdueCount,
                    selected: selected,
                    onTap: () => setState(() {
                      _slideDirection = i > _selectedMonthOffset ? 1 : -1;
                      _selectedMonthOffset = i;
                    }),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // ── Section header ────────────────────────────────────────────────
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

          // ── Task list — directional slide when switching months ───────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) {
              // Incoming child slides in from the direction of travel.
              // Outgoing child fades out in place (no competing slide).
              final isIncoming =
                  (child.key as ValueKey?)?.value == _selectedMonthOffset;
              if (isIncoming) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0.12 * _slideDirection, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                      parent: animation, curve: Curves.easeOut)),
                  child: FadeTransition(opacity: animation, child: child),
                );
              }
              return FadeTransition(opacity: animation, child: child);
            },
            child: monthTasks.isEmpty
                ? _EmptyMonthState(
                    key: ValueKey(_selectedMonthOffset),
                    month: selectedMonth,
                  )
                : _MonthTaskList(
                    key: ValueKey(_selectedMonthOffset),
                    tasks: monthTasks,
                    hidingIds: _hidingTaskIds,
                    onReschedule: _showReschedulePicker,
                  ),
          ),
          const SizedBox(height: AppSizes.xl),
        ],
      );
  }

  Future<void> _showReschedulePicker(MaintenanceTask task) async {
    DateTime picked = task.dueDate.toLocal();
    bool confirmed = false;

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
                      bottom: BorderSide(color: AppColors.border, width: 1)),
                ),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true).pop(),
                      child: Text('Cancel',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary)),
                    ),
                    const Spacer(),
                    Text('Reschedule', style: AppTextStyles.bodyMediumSemibold),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        confirmed = true;
                        Navigator.of(context, rootNavigator: true).pop();
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

    if (!confirmed || !mounted) return;

    // 1. Fade the row out locally before the network write.
    setState(() => _hidingTaskIds.add(task.id));
    await Future.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;

    // 2. Write to DB — provider refresh runs silently (no skeleton flash).
    final now = DateTime.now();
    final todayMid = DateTime(now.year, now.month, now.day);
    final pickedMid = DateTime(picked.year, picked.month, picked.day);
    final newStatus = pickedMid.isBefore(todayMid)
        ? 'overdue'
        : pickedMid.isAtSameMomentAs(todayMid)
            ? 'due'
            : 'scheduled';

    await ref.read(maintenanceTasksProvider.notifier).updateTask(task.id, {
      'due_date': picked.toIso8601String().split('T')[0],
      'status': newStatus,
    });

    ref.invalidate(taskDetailProvider(task.id));
    if (mounted) setState(() => _hidingTaskIds.remove(task.id));
  }
}

// ── Month task list ────────────────────────────────────────────────────────────

/// Renders the bordered task list for a single month. Kept as a separate
/// widget so [AnimatedSwitcher] can diff it cleanly on month change.
class _MonthTaskList extends StatelessWidget {
  const _MonthTaskList({
    super.key,
    required this.tasks,
    required this.hidingIds,
    required this.onReschedule,
  });

  final List<MaintenanceTask> tasks;
  final Set<String> hidingIds;
  final void Function(MaintenanceTask) onReschedule;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          children: [
            for (int i = 0; i < tasks.length; i++) ...[
              AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                opacity: hidingIds.contains(tasks[i].id) ? 0.0 : 1.0,
                child: _PlanTaskRow(
                  task: tasks[i],
                  onReschedule: () => onReschedule(tasks[i]),
                ),
              ),
              if (i < tasks.length - 1)
                Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.warmFill,
                    indent: 38),
            ],
          ],
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
    required this.overdueCount,
    required this.selected,
    required this.onTap,
  });

  final DateTime month;
  final int taskCount;
  final int overdueCount;
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
                      : overdueCount > 0
                          ? AppColors.accent
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
        padding: const EdgeInsets.fromLTRB(0, 12, 14, 12),
        child: Row(
          children: [
            // Overdue left stripe — always present but transparent when not overdue.
            Container(
              width: 3,
              height: 36,
              margin: const EdgeInsets.only(right: 11),
              decoration: BoxDecoration(
                color: isOver ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
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
                      Text(task.category, style: AppTextStyles.caption),
                      Text(' · ', style: AppTextStyles.caption),
                      Text(
                        dueFmt,
                        style: AppTextStyles.caption.copyWith(
                          color: isOver
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (task.recurrence != RecurrenceType.none) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.repeat_rounded,
                            size: 10, color: AppColors.textTertiary),
                        const SizedBox(width: 3),
                        Text(
                          task.recurrence.label,
                          style: AppTextStyles.monoLabel.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            GestureDetector(
              onTap: onReschedule,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
  const _EmptyMonthState({super.key, required this.month});

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
