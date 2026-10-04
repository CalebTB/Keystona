import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_typography.dart';
import '../models/maintenance_task.dart';
import '../providers/maintenance_tasks_provider.dart';
import '../providers/task_detail_provider.dart';
import '../../../core/theme/aurora_radius.dart';

// ── Month helpers ──────────────────────────────────────────────────────────────

/// Returns the first day of [month] months ahead of today (0 = current month).
DateTime _monthStart(int offset) {
  final now = DateTime.now();
  return DateTime(now.year, now.month + offset, 1);
}

bool _sameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

Color _priorityDot(TaskPriority p) => switch (p) {
      TaskPriority.critical => AuroraColors.coral,
      TaskPriority.high => AuroraColors.yellowDeep,
      TaskPriority.medium => AuroraColors.cobalt,
      TaskPriority.low => AuroraColors.inkTertiary,
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
            t.notificationsEnabled &&
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
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: ListView.separated(
              controller: _monthScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 12,
              separatorBuilder: (_, _) => const SizedBox(width: 4),
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
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _slideDirection = i > _selectedMonthOffset ? 1 : -1;
                        _selectedMonthOffset = i;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // ── Section header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  DateFormat('MMMM').format(selectedMonth).toUpperCase(),
                  style: AuroraType.label,
                ),
                const SizedBox(width: 8),
                Text(
                  '$totalForMonth task${totalForMonth == 1 ? '' : 's'}',
                  style: AuroraType.label
                      .copyWith(color: AuroraColors.inkSecondary),
                ),
                if (overdueInMonth > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AuroraColors.coral.withValues(alpha: 0.12),
                      borderRadius: AuroraRadius.xs,
                    ),
                    child: Text(
                      '$overdueInMonth overdue',
                      style: AuroraType.label
                          .copyWith(color: AuroraColors.coral),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

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
          const SizedBox(height: 20),
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
          color: AuroraColors.paper,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: AuroraColors.inkBorder, width: 1)),
                ),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true).pop(),
                      child: Text('Cancel',
                          style: AuroraType.body
                              .copyWith(color: AuroraColors.inkSecondary)),
                    ),
                    const Spacer(),
                    Text('Reschedule', style: AuroraType.body.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        confirmed = true;
                        HapticFeedback.mediumImpact();
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                      child: Text('Done',
                          style: AuroraType.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AuroraColors.coral,
                          )),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AuroraColors.paper,
          borderRadius: AuroraRadius.lg,
          border: Border.all(color: AuroraColors.inkBorder, width: 1.5),
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
                    color: AuroraColors.butter,
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
          color: selected ? AuroraColors.ink : Colors.transparent,
          borderRadius: AuroraRadius.md,
          border: selected
              ? null
              : Border.all(color: AuroraColors.inkBorder, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('MMM').format(month),
              style: AuroraType.label.copyWith(
                color: selected
                    ? AuroraColors.paper
                    : isPast
                        ? AuroraColors.inkTertiary
                        : AuroraColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            if (taskCount > 0)
              Text(
                '$taskCount',
                style: AuroraType.labelSm.copyWith(
                  color: selected
                      ? AuroraColors.paper.withValues(alpha: 0.6)
                      : overdueCount > 0
                          ? AuroraColors.coral
                          : AuroraColors.inkSecondary,
                ),
              )
            else
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: selected
                      ? AuroraColors.paper.withValues(alpha: 0.4)
                      : AuroraColors.inkBorder,
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
                color: isOver ? AuroraColors.coral : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isOver ? AuroraColors.coral : dot,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.name, style: AuroraType.body),
                  Row(
                    children: [
                      Text(task.category, style: AuroraType.bodySm),
                      Text(' · ', style: AuroraType.bodySm),
                      Text(
                        dueFmt,
                        style: AuroraType.bodySm.copyWith(
                          color: isOver
                              ? AuroraColors.coral
                              : AuroraColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (task.recurrence != RecurrenceType.none) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.repeat_rounded,
                            size: 10, color: AuroraColors.inkTertiary),
                        const SizedBox(width: 3),
                        Text(
                          task.recurrence.label,
                          style: AuroraType.label.copyWith(
                            color: AuroraColors.inkTertiary,
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
                  color: AuroraColors.butter,
                  borderRadius: AuroraRadius.xs,
                ),
                child: Text(
                  'Reschedule',
                  style: AuroraType.labelSm.copyWith(
                    color: AuroraColors.inkSecondary,
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AuroraColors.paper,
          borderRadius: AuroraRadius.lg,
          border: Border.all(color: AuroraColors.inkBorder, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 28, color: AuroraColors.inkTertiary),
            const SizedBox(height: 8),
            Text(
              'Nothing in ${DateFormat('MMMM').format(month)}',
              style: AuroraType.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'No tasks due this month.',
              style: AuroraType.bodySm.copyWith(
                color: AuroraColors.inkSecondary,
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
      baseColor: AuroraColors.butter,
      highlightColor: AuroraColors.paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: Row(
              children: [
                const SizedBox(width: 16),
                for (int i = 0; i < 5; i++) ...[
                  Container(
                    width: 58,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AuroraColors.butter,
                      borderRadius: AuroraRadius.md,
                    ),
                  ),
                  if (i < 4) const SizedBox(width: 4),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: AuroraColors.butter,
                borderRadius: AuroraRadius.lg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
