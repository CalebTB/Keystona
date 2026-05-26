import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

    int overdueCount(List<MaintenanceTask> list) => list.where((t) {
          final due = t.dueDate.toLocal();
          final dueMid = DateTime(due.year, due.month, due.day);
          return t.status == TaskStatus.overdue || dueMid.isBefore(todayMid);
        }).length;

    final withTasks = systems.where((s) => grouped.containsKey(s.id)).toList()
      ..sort((a, b) => overdueCount(grouped[b.id]!)
          .compareTo(overdueCount(grouped[a.id]!)));
    final withoutTasks =
        systems.where((s) => !grouped.containsKey(s.id)).toList();

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.md),
          // System cards with tasks
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
            child: Column(
              children: [
                ...withTasks.map(
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
          // All Clear — horizontal chip strip
          if (withoutTasks.isNotEmpty) ...[
            const SizedBox(height: AppSizes.xs),
            Padding(
              padding: const EdgeInsets.only(left: AppSizes.screenPadding),
              child: Text('ALL CLEAR', style: AppTextStyles.monoSection),
            ),
            const SizedBox(height: AppSizes.sm),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.screenPadding),
                itemCount: withoutTasks.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSizes.sm),
                itemBuilder: (_, i) => _AllClearChip(system: withoutTasks[i]),
              ),
            ),
          ],
          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }
}

// ── System card (has tasks) ────────────────────────────────────────────────────

const int _kPreviewCount = 3;

class _SystemCard extends StatefulWidget {
  const _SystemCard({required this.system, required this.tasks});

  final HomeSystem system;
  final List<MaintenanceTask> tasks;

  @override
  State<_SystemCard> createState() => _SystemCardState();
}

class _SystemCardState extends State<_SystemCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final color = _systemColor(widget.system.category);
    final icon = _systemIcon(widget.system.category);

    final sorted = [...widget.tasks]..sort((a, b) {
        final keyCmp = _taskSortKey(a).compareTo(_taskSortKey(b));
        if (keyCmp != 0) return keyCmp;
        return a.dueDate.compareTo(b.dueDate);
      });

    final preview = sorted.take(_kPreviewCount).toList();
    final hidden = sorted.skip(_kPreviewCount).toList();
    final hasMore = hidden.isNotEmpty;

    final systemName = widget.system.brand != null
        ? '${widget.system.brand} ${widget.system.name}'
        : widget.system.name;
    final year = _installYear(widget.system.installationDate);
    final location = widget.system.location;

    return ClipRRect(
      borderRadius: AppRadius.card,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          children: [
            // ── Dark header ──────────────────────────────────────────
            Container(
              color: AppColors.deepNavy,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  // System icon badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 22, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          systemName,
                          style: AppTextStyles.bodyMediumSemibold.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Health dot
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _healthColor(widget.system),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            if (location != null && location.isNotEmpty) ...[
                              Text(
                                location,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.darkTextSecondary,
                                ),
                              ),
                              if (year != null)
                                Text(
                                  '  ·  ',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.darkTextTertiary,
                                  ),
                                ),
                            ],
                            if (year != null)
                              Text(
                                year,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.darkTextSecondary,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Task list ────────────────────────────────────────────
            ...preview.map((t) => _TaskRow(task: t)),
            ClipRect(
              child: AnimatedAlign(
                alignment: Alignment.topCenter,
                heightFactor: _expanded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                child: Column(
                  children: hidden.map((t) => _TaskRow(task: t)).toList(),
                ),
              ),
            ),
            if (hasMore)
              _ExpandFooter(
                expanded: _expanded,
                hiddenCount: hidden.length,
                onTap: () => setState(() => _expanded = !_expanded),
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
    final dot = _taskDotColor(task);
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
                  // Status dot / check icon
                  SizedBox(
                    width: 16,
                    child: isDone && task.status == TaskStatus.completed
                        ? Icon(Icons.check_circle_outline,
                            size: 14, color: AppColors.olive)
                        : Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(top: 1),
                            decoration: BoxDecoration(
                              color: dot,
                              shape: BoxShape.circle,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
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

// ── Expand footer ──────────────────────────────────────────────────────────────

class _ExpandFooter extends StatelessWidget {
  const _ExpandFooter({
    required this.expanded,
    required this.hiddenCount,
    required this.onTap,
  });

  final bool expanded;
  final int hiddenCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 36,
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.warmFill, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!expanded)
              Text(
                '$hiddenCount more',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(width: 3),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubic,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
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
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.tasks]..sort((a, b) {
        final keyCmp = _taskSortKey(a).compareTo(_taskSortKey(b));
        if (keyCmp != 0) return keyCmp;
        return a.dueDate.compareTo(b.dueDate);
      });

    final preview = sorted.take(_kPreviewCount).toList();
    final hidden = sorted.skip(_kPreviewCount).toList();
    final hasMore = hidden.isNotEmpty;

    return ClipRRect(
      borderRadius: AppRadius.card,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          children: [
            // Dark header — neutral tone for uncategorized
            Container(
              color: AppColors.gray700,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.checklist_rounded,
                        size: 22, color: AppColors.gray300),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'General Tasks',
                          style: AppTextStyles.bodyMediumSemibold.copyWith(
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'No system linked',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ...preview.map((t) => _TaskRow(task: t)),
            ClipRect(
              child: AnimatedAlign(
                alignment: Alignment.topCenter,
                heightFactor: _expanded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                child: Column(
                  children: hidden.map((t) => _TaskRow(task: t)).toList(),
                ),
              ),
            ),
            if (hasMore)
              _ExpandFooter(
                expanded: _expanded,
                hiddenCount: hidden.length,
                onTap: () => setState(() => _expanded = !_expanded),
              ),
          ],
        ),
      ),
    );
  }
}

// ── All Clear chip ─────────────────────────────────────────────────────────────

class _AllClearChip extends StatelessWidget {
  const _AllClearChip({required this.system});
  final HomeSystem system;

  @override
  Widget build(BuildContext context) {
    final color = _systemColor(system.category);
    final icon = _systemIcon(system.category);
    final name = system.brand != null
        ? '${system.brand}\n${system.name}'
        : system.name;

    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: color.withValues(alpha: 0.45)),
          const SizedBox(height: 6),
          Text(
            name,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'All clear',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.olive,
              fontSize: 10,
              fontWeight: FontWeight.w600,
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
