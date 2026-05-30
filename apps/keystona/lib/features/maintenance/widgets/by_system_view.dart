import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home_profile/models/system.dart';
import '../../home_profile/providers/systems_provider.dart';
import '../models/maintenance_task.dart';
import '../providers/maintenance_tasks_provider.dart';

// ── Category helpers ───────────────────────────────────────────────────────────

IconData _systemIcon(SystemCategory cat) => switch (cat) {
      SystemCategory.hvac => Icons.ac_unit_outlined,
      SystemCategory.plumbing => Icons.water_drop_outlined,
      SystemCategory.electrical => Icons.electrical_services_outlined,
      SystemCategory.roofing => Icons.roofing_outlined,
      SystemCategory.foundation => Icons.foundation_outlined,
      SystemCategory.siding => Icons.home_outlined,
      SystemCategory.windowsDoors => Icons.window_outlined,
      SystemCategory.insulation => Icons.layers_outlined,
      SystemCategory.garage => Icons.garage_outlined,
      SystemCategory.other => Icons.build_outlined,
    };

Color _systemColor(SystemCategory cat) => switch (cat) {
      SystemCategory.hvac => AppColors.slate,
      SystemCategory.plumbing => AppColors.teal,
      SystemCategory.electrical => AppColors.sandAmber,
      SystemCategory.roofing => AppColors.sand,
      SystemCategory.foundation => AppColors.gray500,
      SystemCategory.siding => AppColors.olive,
      SystemCategory.windowsDoors => AppColors.slate,
      SystemCategory.insulation => AppColors.amber,
      SystemCategory.garage => AppColors.gray400,
      SystemCategory.other => AppColors.gray400,
    };

Color _healthColor(HomeSystem system) => switch (system.status) {
      ItemStatus.active => AppColors.oliveLight,
      ItemStatus.needsRepair => AppColors.sand,
      _ => AppColors.gray400,
    };

Color _taskDotColor(MaintenanceTask t) {
  if (t.status == TaskStatus.completed) return AppColors.olive;
  if (t.status == TaskStatus.skipped) return AppColors.gray300;
  final today = DateTime.now();
  final todayMid = DateTime(today.year, today.month, today.day);
  final due = t.dueDate.toLocal();
  final dueMid = DateTime(due.year, due.month, due.day);
  if (t.status == TaskStatus.overdue || dueMid.isBefore(todayMid)) {
    return AppColors.accent;
  }
  if (dueMid == todayMid) return AppColors.sandAmber;
  final weekOut = todayMid.add(const Duration(days: 7));
  if (dueMid.isBefore(weekOut)) return AppColors.sand;
  return AppColors.slate;
}

// ── Context label ──────────────────────────────────────────────────────────────

typedef _Label = ({String text, Color color});

DateTime? _nextDueDate(MaintenanceTask t) {
  final base = t.dueDate.toLocal();
  return switch (t.recurrence) {
    RecurrenceType.none => null,
    RecurrenceType.weekly => base.add(const Duration(days: 7)),
    RecurrenceType.biweekly => base.add(const Duration(days: 14)),
    RecurrenceType.monthly => DateTime(base.year, base.month + 1, base.day),
    RecurrenceType.quarterly => DateTime(base.year, base.month + 3, base.day),
    RecurrenceType.biannual => DateTime(base.year, base.month + 6, base.day),
    RecurrenceType.annual => DateTime(base.year + 1, base.month, base.day),
  };
}

_Label _contextLabel(MaintenanceTask t) {
  if (t.status == TaskStatus.completed) {
    final next = _nextDueDate(t);
    if (next == null) return (text: 'Done', color: AppColors.olive);
    final today = DateTime.now();
    final todayMid = DateTime(today.year, today.month, today.day);
    final nextMid = DateTime(next.year, next.month, next.day);
    final diff = nextMid.difference(todayMid).inDays;
    if (diff <= 0) return (text: 'Due again', color: AppColors.sandAmber);
    if (diff == 1) return (text: 'Due tomorrow', color: AppColors.sandAmber);
    if (diff <= 7) return (text: 'Good for $diff days', color: AppColors.slate);
    if (diff <= 60) {
      final weeks = (diff / 7).round();
      return (text: 'Good for $weeks wk', color: AppColors.slate);
    }
    final months = (diff / 30).round();
    if (months < 12) return (text: 'Good for $months mo', color: AppColors.olive);
    return (text: '~1 year', color: AppColors.olive);
  }
  if (t.status == TaskStatus.skipped) {
    return (text: 'Skipped', color: AppColors.gray400);
  }

  final today = DateTime.now();
  final todayMid = DateTime(today.year, today.month, today.day);
  final due = t.dueDate.toLocal();
  final dueMid = DateTime(due.year, due.month, due.day);
  final diff = dueMid.difference(todayMid).inDays;

  if (t.status == TaskStatus.overdue || dueMid.isBefore(todayMid)) {
    final daysAgo = todayMid.difference(dueMid).inDays;
    if (daysAgo <= 1) return (text: 'Overdue', color: AppColors.accent);
    if (daysAgo <= 14) return (text: '${daysAgo}d overdue', color: AppColors.accent);
    final weeks = (daysAgo / 7).round();
    if (weeks <= 8) return (text: '${weeks}wk overdue', color: AppColors.accent);
    final months = (daysAgo / 30).round();
    return (text: '${months}mo overdue', color: AppColors.accent);
  }
  if (diff == 0) return (text: 'Due today', color: AppColors.sandAmber);
  if (diff == 1) return (text: 'Due tomorrow', color: AppColors.sandAmber);
  if (diff <= 7) return (text: 'Due this week', color: AppColors.sandAmber);
  if (diff <= 31) return (text: 'Due this month', color: AppColors.sand);
  if (diff <= 60) {
    final weeks = (diff / 7).round();
    return (text: 'Good for $weeks wk', color: AppColors.slate);
  }
  final months = (diff / 30).round();
  if (months < 12) return (text: 'Good for $months mo', color: AppColors.slate);
  return (text: '~1 year', color: AppColors.olive);
}

int _taskSortKey(MaintenanceTask t) {
  if (t.status == TaskStatus.skipped) return 5;
  if (t.status == TaskStatus.completed) return 4;
  final dot = _taskDotColor(t);
  if (dot == AppColors.accent) return 0;
  if (dot == AppColors.sandAmber) return 1;
  if (dot == AppColors.sand) return 2;
  return 3;
}

String? _installYear(String? date) {
  if (date == null || date.length < 4) return null;
  return date.substring(0, 4);
}

// ── Main sliver widget ─────────────────────────────────────────────────────────

class BySystemView extends ConsumerWidget {
  const BySystemView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemsAsync = ref.watch(systemsProvider);
    final tasksAsync = ref.watch(maintenanceTasksProvider);

    if (systemsAsync.isLoading || tasksAsync.isLoading) {
      return _BySystemSkeleton();
    }

    final systems = systemsAsync.value ?? [];
    final tasks = tasksAsync.value ?? [];

    if (systems.isEmpty) {
      return _NoSystemsEmptyState();
    }

    final today = DateTime.now();
    final todayMid = DateTime(today.year, today.month, today.day);

    final Map<String, List<MaintenanceTask>> grouped = {};
    final List<MaintenanceTask> uncategorized = [];

    for (final t in tasks) {
      if (t.status == TaskStatus.completed && t.recurrence == RecurrenceType.none) {
        continue;
      }
      if (t.linkedSystemId != null) {
        grouped.putIfAbsent(t.linkedSystemId!, () => []).add(t);
      } else {
        uncategorized.add(t);
      }
    }

    final thirtyDaysOut = todayMid.add(const Duration(days: 30));

    // A system is "all clear" when every active task is 30+ days out.
    // Systems with no tasks at all also qualify as all clear.
    bool isAllClear(String systemId) {
      final list = grouped[systemId] ?? [];
      for (final t in list) {
        if (t.status == TaskStatus.completed ||
            t.status == TaskStatus.skipped) {
          continue;
        }
        final due = t.dueDate.toLocal();
        final dueMid = DateTime(due.year, due.month, due.day);
        if (t.status == TaskStatus.overdue ||
            dueMid.isBefore(thirtyDaysOut)) {
          return false;
        }
      }
      return true;
    }

    int overdueCount(List<MaintenanceTask> list) => list.where((t) {
          final due = t.dueDate.toLocal();
          final dueMid = DateTime(due.year, due.month, due.day);
          return t.status == TaskStatus.overdue || dueMid.isBefore(todayMid);
        }).length;

    // Systems needing attention: have tasks due within 30 days or overdue.
    final attentionSystems = systems
        .where((s) => grouped.containsKey(s.id) && !isAllClear(s.id))
        .toList()
      ..sort((a, b) => overdueCount(grouped[b.id]!)
          .compareTo(overdueCount(grouped[a.id]!)));

    // All-clear systems: no tasks linked, or all tasks are 30+ days out.
    final clearSystems =
        systems.where((s) => isAllClear(s.id)).toList();

    // Tasks keyed by system ID for the all-clear card's next-due hints.
    final Map<String, List<MaintenanceTask>> clearSystemTasks = {
      for (final s in clearSystems)
        if (grouped.containsKey(s.id)) s.id: grouped[s.id]!,
    };

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.md),
          // Systems needing attention
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenPadding),
            child: Column(
              children: [
                ...attentionSystems.map(
                  (system) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.sm),
                    child: _SystemCard(
                      system: system,
                      tasks: grouped[system.id]!,
                    ),
                  ),
                ),
                if (uncategorized.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.sm),
                    child: _UncategorizedCard(tasks: uncategorized),
                  ),
              ],
            ),
          ),
          // All Clear
          if (clearSystems.isNotEmpty) ...[
            const SizedBox(height: AppSizes.xs),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenPadding),
              child: _AllClearCard(
                systems: clearSystems,
                tasksBySystem: clearSystemTasks,
              ),
            ),
          ],
          const SizedBox(height: AppSizes.xl),
        ],
      );
  }
}

// ── System card (has tasks) ────────────────────────────────────────────────────


class _SystemCard extends StatefulWidget {
  const _SystemCard({required this.system, required this.tasks});

  final HomeSystem system;
  final List<MaintenanceTask> tasks;

  @override
  State<_SystemCard> createState() => _SystemCardState();
}

class _SystemCardState extends State<_SystemCard> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final color = _systemColor(widget.system.category);
    final icon = _systemIcon(widget.system.category);

    final sorted = [...widget.tasks]..sort((a, b) {
        final keyCmp = _taskSortKey(a).compareTo(_taskSortKey(b));
        if (keyCmp != 0) return keyCmp;
        return a.dueDate.compareTo(b.dueDate);
      });

    final systemName = widget.system.brand != null
        ? '${widget.system.brand} ${widget.system.name}'
        : widget.system.name;
    final year = _installYear(widget.system.installationDate);
    final location = widget.system.location;
    final count = sorted.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1A2B4A),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.card,
        child: Column(
          children: [
            // ── Header — tap to collapse/expand ──────────────────────
            GestureDetector(
              onTap: () => setState(() => _collapsed = !_collapsed),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                child: Row(
                  children: [
                    // Icon badge — tap to open system detail
                    GestureDetector(
                      onTap: () =>
                          context.push('/home/systems/${widget.system.id}'),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, size: 20, color: color),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            systemName,
                            style: AppTextStyles.bodyMediumSemibold,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _healthColor(widget.system),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              if (location != null &&
                                  location.isNotEmpty) ...[
                                Text(
                                  location,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (year != null)
                                  Text(
                                    '  ·  ',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                              ],
                              if (year != null)
                                Text(
                                  year,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Task count — always visible
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warmFill,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.border, width: 1),
                      ),
                      child: Text(
                        '$count',
                        style: AppTextStyles.monoTiny.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _collapsed ? 0.25 : 0,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeInOutCubic,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Task list — collapses on header tap ───────────────────
            ClipRect(
              child: AnimatedAlign(
                alignment: Alignment.topCenter,
                heightFactor: _collapsed ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                child: Column(
                  children: [
                    const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.border),
                    ...sorted.map((t) => _TaskRow(task: t)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Task row ──────────────────────────────────────────────────────────────────

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});
  final MaintenanceTask task;

  @override
  Widget build(BuildContext context) {
    final label = _contextLabel(task);
    final isDone = task.status == TaskStatus.skipped ||
        (task.status == TaskStatus.completed && _nextDueDate(task) == null);

    return GestureDetector(
      onTap: () => context.push('/maintenance/${task.id}'),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
            child: Opacity(
              opacity: isDone ? 0.5 : 1.0,
              child: Row(
                children: [
                  if (isDone && task.status == TaskStatus.completed) ...[
                    Icon(Icons.check_circle_outline,
                        size: 14, color: AppColors.olive),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      task.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        decoration:
                            isDone ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Status label pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: label.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      label.text,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: label.color,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(
              height: 1,
              thickness: 1,
              color: AppColors.warmFill,
              indent: 42),
        ],
      ),
    );
  }
}


// ── Uncategorized tasks card ───────────────────────────────────────────────────

class _UncategorizedCard extends StatefulWidget {
  const _UncategorizedCard({required this.tasks});
  final List<MaintenanceTask> tasks;

  @override
  State<_UncategorizedCard> createState() => _UncategorizedCardState();
}

class _UncategorizedCardState extends State<_UncategorizedCard> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.tasks]..sort((a, b) {
        final keyCmp = _taskSortKey(a).compareTo(_taskSortKey(b));
        if (keyCmp != 0) return keyCmp;
        return a.dueDate.compareTo(b.dueDate);
      });

    final count = sorted.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1A2B4A),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.card,
        child: Column(
          children: [
            // Header — tap to collapse/expand
            GestureDetector(
              onTap: () => setState(() => _collapsed = !_collapsed),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.warmFill,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.checklist_rounded,
                          size: 20, color: AppColors.gray400),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'General Tasks',
                            style: AppTextStyles.bodyMediumSemibold,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'No system linked',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warmFill,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.border, width: 1),
                      ),
                      child: Text(
                        '$count',
                        style: AppTextStyles.monoTiny.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _collapsed ? 0.25 : 0,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeInOutCubic,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ClipRect(
              child: AnimatedAlign(
                alignment: Alignment.topCenter,
                heightFactor: _collapsed ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                child: Column(
                  children: [
                    const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.border),
                    ...sorted.map((t) => _TaskRow(task: t)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── All Clear card ─────────────────────────────────────────────────────────────

class _AllClearCard extends StatelessWidget {
  const _AllClearCard({
    required this.systems,
    required this.tasksBySystem,
  });

  final List<HomeSystem> systems;
  /// Tasks keyed by system ID — used to show the next upcoming due date.
  final Map<String, List<MaintenanceTask>> tasksBySystem;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.oliveDim,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: AppColors.olive.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.olive.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: AppColors.olive,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${systems.length} system${systems.length > 1 ? 's' : ''} in good standing',
                    style: AppTextStyles.bodyMediumSemibold.copyWith(
                      color: AppColors.olive,
                    ),
                  ),
                  Text(
                    'All tasks 30+ days out',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: systems.map((s) {
              final color = _systemColor(s.category);
              final icon = _systemIcon(s.category);

              // Find the soonest upcoming task for this system.
              final sysTasks = tasksBySystem[s.id] ?? [];
              final pending = sysTasks
                  .where((t) =>
                      t.status != TaskStatus.completed &&
                      t.status != TaskStatus.skipped)
                  .toList()
                ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
              final nextDue = pending.isEmpty ? null : pending.first.dueDate.toLocal();

              return GestureDetector(
                onTap: () => context.push('/home/systems/${s.id}'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 13, color: color.withValues(alpha: 0.7)),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.name,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 11,
                            ),
                          ),
                          if (nextDue != null)
                            Text(
                              'Next ${DateFormat('MMM d').format(nextDue)}',
                              style: AppTextStyles.monoLabel.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 10,
                              ),
                            )
                          else
                            Text(
                              'No tasks yet',
                              style: AppTextStyles.monoLabel.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 13,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── No systems empty state ─────────────────────────────────────────────────────

class _NoSystemsEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
      child: Column(
        children: [
          const SizedBox(height: AppSizes.xl),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.xl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.slate.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Icon(Icons.home_repair_service_outlined,
                      size: 26, color: AppColors.slate),
                ),
                const SizedBox(height: AppSizes.md),
                Text('No systems added yet',
                    style: AppTextStyles.bodyMediumSemibold),
                const SizedBox(height: 4),
                Text(
                  'Add your home systems in Home Profile\nto see tasks organized by system.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ───────────────────────────────────────────────────────────────────

class _BySystemSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.gray200,
      highlightColor: AppColors.gray100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSizes.md),
            const _SkeletonSystemCard(),
            const SizedBox(height: AppSizes.sm),
            const _SkeletonSystemCard(),
            const SizedBox(height: AppSizes.sm),
            const _SkeletonSystemCard(),
          ],
        ),
      ),
    );
  }
}

class _SkeletonSystemCard extends StatelessWidget {
  const _SkeletonSystemCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.card,
      child: Column(
        children: [
          // Dark header skeleton
          Container(
            height: 72,
            color: AppColors.gray300,
          ),
          // Task row skeletons
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: Column(
              children: [
                _SkeletonTaskRow(),
                const SizedBox(height: 10),
                _SkeletonTaskRow(),
                const SizedBox(height: 10),
                _SkeletonTaskRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonTaskRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 7, height: 7, decoration: const BoxDecoration(
          color: AppColors.gray200, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(
          child: Container(height: 12, color: AppColors.gray200),
        ),
        const SizedBox(width: 10),
        Container(
          width: 64,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.gray200,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }
}
