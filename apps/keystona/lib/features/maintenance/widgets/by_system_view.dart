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
      SystemCategory.roofing => AppColors.deepNavy,
      SystemCategory.foundation => AppColors.gray600,
      SystemCategory.siding => AppColors.olive,
      SystemCategory.windowsDoors => AppColors.slate,
      SystemCategory.insulation => AppColors.amber,
      SystemCategory.garage => AppColors.gray500,
      SystemCategory.other => AppColors.gray400,
    };

String _healthLabel(HomeSystem system) => switch (system.status) {
      ItemStatus.active => 'Healthy',
      ItemStatus.needsRepair => 'Aging',
      ItemStatus.replaced => 'Replaced',
      ItemStatus.removed => 'Removed',
    };

Color _healthColor(HomeSystem system) => switch (system.status) {
      ItemStatus.active => AppColors.olive,
      ItemStatus.needsRepair => AppColors.sand,
      _ => AppColors.gray400,
    };

Color _taskDotColor(MaintenanceTask t) {
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

String _dueDateLabel(MaintenanceTask t) {
  final today = DateTime.now();
  final todayMid = DateTime(today.year, today.month, today.day);
  final due = t.dueDate.toLocal();
  final dueMid = DateTime(due.year, due.month, due.day);
  final diff = dueMid.difference(todayMid).inDays;

  if (t.status == TaskStatus.overdue || dueMid.isBefore(todayMid)) {
    final daysAgo = todayMid.difference(dueMid).inDays;
    if (daysAgo == 0) return 'Overdue today';
    final months = (daysAgo / 30).round();
    if (months >= 2) return '${months}mo overdue';
    final weeks = (daysAgo / 7).round();
    if (weeks >= 2) return '${weeks}wk overdue';
    return '${daysAgo}d overdue';
  }
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff <= 7) return 'Due in $diff days';
  return 'Due ${DateFormat('MMM d').format(dueMid)}';
}

String _installedLabel(String? date) {
  if (date == null || date.length < 4) return '';
  return 'Installed ${date.substring(0, 4)}';
}

// ── Main sliver widget ─────────────────────────────────────────────────────────

class BySystemViewSliver extends ConsumerWidget {
  const BySystemViewSliver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemsAsync = ref.watch(systemsProvider);
    final tasksAsync = ref.watch(maintenanceTasksProvider);

    if (systemsAsync.isLoading || tasksAsync.isLoading) {
      return SliverToBoxAdapter(child: _BySystemSkeleton());
    }

    final systems = systemsAsync.value ?? [];
    final tasks = tasksAsync.value ?? [];

    if (systems.isEmpty) {
      return SliverToBoxAdapter(child: _NoSystemsEmptyState());
    }

    // Group non-completed tasks by linked system id.
    final today = DateTime.now();
    final todayMid = DateTime(today.year, today.month, today.day);

    Map<String, List<MaintenanceTask>> grouped = {};
    List<MaintenanceTask> uncategorized = [];

    for (final t in tasks) {
      if (t.status == TaskStatus.completed || t.status == TaskStatus.skipped) {
        continue;
      }
      if (t.linkedSystemId != null) {
        grouped.putIfAbsent(t.linkedSystemId!, () => []).add(t);
      } else {
        uncategorized.add(t);
      }
    }

    int overdueCount(List<MaintenanceTask> list) => list.where((t) {
          final due = t.dueDate.toLocal();
          final dueMid = DateTime(due.year, due.month, due.day);
          return t.status == TaskStatus.overdue || dueMid.isBefore(todayMid);
        }).length;

    // Systems with tasks first, sorted by overdue count desc, then others.
    final withTasks = systems.where((s) => grouped.containsKey(s.id)).toList()
      ..sort((a, b) => overdueCount(grouped[b.id]!)
          .compareTo(overdueCount(grouped[a.id]!)));
    final withoutTasks =
        systems.where((s) => !grouped.containsKey(s.id)).toList();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSizes.md),
            ...withTasks.map(
              (system) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.sm),
                child: _SystemCard(
                  system: system,
                  tasks: grouped[system.id]!,
                ),
              ),
            ),
            if (uncategorized.isNotEmpty) ...[
              const SizedBox(height: AppSizes.xs),
              _UncategorizedCard(tasks: uncategorized),
              const SizedBox(height: AppSizes.sm),
            ],
            if (withoutTasks.isNotEmpty) ...[
              const SizedBox(height: AppSizes.xs),
              Text('ALL CLEAR', style: AppTextStyles.monoSection),
              const SizedBox(height: AppSizes.sm),
              ...withoutTasks.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.sm),
                  child: _SystemCardEmpty(system: s),
                ),
              ),
            ],
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }
}

// ── System card (has tasks) ────────────────────────────────────────────────────

class _SystemCard extends StatelessWidget {
  const _SystemCard({required this.system, required this.tasks});

  final HomeSystem system;
  final List<MaintenanceTask> tasks;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayMid = DateTime(today.year, today.month, today.day);
    final overdueCount = tasks.where((t) {
      final due = t.dueDate.toLocal();
      final dueMid = DateTime(due.year, due.month, due.day);
      return t.status == TaskStatus.overdue || dueMid.isBefore(todayMid);
    }).length;

    final color = _systemColor(system.category);
    final icon = _systemIcon(system.category);
    final health = _healthLabel(system);
    final healthColor = _healthColor(system);
    final installed = _installedLabel(system.installationDate);

    // Sort tasks: overdue first, then by due date.
    final sorted = [...tasks]..sort((a, b) {
        final aDot = _taskDotColor(a);
        final bDot = _taskDotColor(b);
        // accent (overdue) first
        if (aDot == AppColors.accent && bDot != AppColors.accent) return -1;
        if (bDot == AppColors.accent && aDot != AppColors.accent) return 1;
        return a.dueDate.compareTo(b.dueDate);
      });

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          // System header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        system.brand != null
                            ? '${system.brand} ${system.name}'
                            : system.name,
                        style: AppTextStyles.bodyMediumSemibold,
                      ),
                      Row(
                        children: [
                          if (installed.isNotEmpty) ...[
                            Text(
                              installed,
                              style: AppTextStyles.caption,
                            ),
                            Text(
                              '  ·  ',
                              style: AppTextStyles.caption,
                            ),
                          ],
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: healthColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            health,
                            style: AppTextStyles.caption
                                .copyWith(color: healthColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (overdueCount > 0)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$overdueCount',
                        style: AppTextStyles.monoSection.copyWith(
                          color: Colors.white,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Divider
          Divider(height: 1, thickness: 1, color: AppColors.warmFill),
          // Task rows
          ...sorted.map((t) => _TaskRow(task: t)),
          // Footer
          _CardFooter(tasks: tasks),
        ],
      ),
    );
  }
}

// ── Task row inside system card ────────────────────────────────────────────────

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final MaintenanceTask task;

  @override
  Widget build(BuildContext context) {
    final dot = _taskDotColor(task);
    final dateLabel = _dueDateLabel(task);
    final recurrence = task.recurrence != RecurrenceType.none
        ? task.recurrence.label.toLowerCase()
        : null;

    return GestureDetector(
      onTap: () =>
          context.push('/maintenance/${task.id}'),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dot,
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
                            dateLabel,
                            style: AppTextStyles.caption.copyWith(
                              color: dot == AppColors.accent
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                            ),
                          ),
                          if (recurrence != null) ...[
                            Text(
                              ' · ',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                            Text(
                              recurrence,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: AppColors.warmFill, indent: 32),
        ],
      ),
    );
  }
}

// ── Card footer ────────────────────────────────────────────────────────────────

class _CardFooter extends StatelessWidget {
  const _CardFooter({required this.tasks});

  final List<MaintenanceTask> tasks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Row(
        children: [
          Text(
            'View all ${tasks.length} task${tasks.length == 1 ? '' : 's'}',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 2),
          Icon(Icons.chevron_right, size: 14, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

// ── Uncategorized tasks card ───────────────────────────────────────────────────

class _UncategorizedCard extends StatelessWidget {
  const _UncategorizedCard({required this.tasks});

  final List<MaintenanceTask> tasks;

  @override
  Widget build(BuildContext context) {
    final sorted = [...tasks]
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.warmFill,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Icon(Icons.checklist_outlined,
                      size: 20, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('General Tasks',
                          style: AppTextStyles.bodyMediumSemibold),
                      Text('No system linked',
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: AppColors.warmFill),
          ...sorted.map((t) => _TaskRow(task: t)),
          _CardFooter(tasks: tasks),
        ],
      ),
    );
  }
}

// ── System card (no tasks = all clear) ────────────────────────────────────────

class _SystemCardEmpty extends StatelessWidget {
  const _SystemCardEmpty({required this.system});

  final HomeSystem system;

  @override
  Widget build(BuildContext context) {
    final color = _systemColor(system.category);
    final icon = _systemIcon(system.category);
    final installed = _installedLabel(system.installationDate);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, size: 20, color: color.withValues(alpha: 0.4)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  system.brand != null
                      ? '${system.brand} ${system.name}'
                      : system.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (installed.isNotEmpty)
                  Text(installed, style: AppTextStyles.caption),
              ],
            ),
          ),
          Text(
            '0',
            style: AppTextStyles.monoLabel.copyWith(
              color: AppColors.gray400,
            ),
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
            _SkeletonSystemCard(),
            const SizedBox(height: AppSizes.sm),
            _SkeletonSystemCard(),
            const SizedBox(height: AppSizes.sm),
            _SkeletonSystemCard(),
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
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: AppRadius.card,
      ),
    );
  }
}
