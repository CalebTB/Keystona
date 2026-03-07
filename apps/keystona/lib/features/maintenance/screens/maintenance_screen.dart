import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../models/maintenance_task.dart';
import '../providers/maintenance_tasks_provider.dart';
import '../providers/task_filter_provider.dart';
import '../widgets/health_score_widget.dart';
import '../widgets/task_card.dart';
import '../widgets/task_empty_state.dart';
import '../widgets/task_list_skeleton.dart';

/// The Maintenance Calendar screen — Tab 2 of the main shell.
///
/// Adaptive layout:
/// - iOS: CupertinoPageScaffold with CupertinoSliverNavigationBar large title.
/// - Android: Scaffold with SliverAppBar.
///
/// Both layouts share a filter chip row (All / Overdue / Due Soon / Upcoming /
/// Completed) and a grouped task list with section headers.
class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return isIOS
        ? const _IOSMaintenanceLayout()
        : const _AndroidMaintenanceLayout();
  }
}

// ── iOS layout ────────────────────────────────────────────────────────────────

class _IOSMaintenanceLayout extends ConsumerWidget {
  const _IOSMaintenanceLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: const Text('Tasks'),
                trailing: _SortButton(
                  isIOS: true,
                  onSortSelected: (order) =>
                      ref.read(taskFilterProvider.notifier).setSortOrder(order),
                  onGenerateTasks: () => _generateTasks(ref),
                ),
              ),
              CupertinoSliverRefreshControl(
                onRefresh: () =>
                    ref.read(maintenanceTasksProvider.notifier).refresh(),
              ),
              // Health score card.
              const SliverToBoxAdapter(child: HealthScoreWidget()),
              // Filter chip row.
              const SliverToBoxAdapter(child: _FilterRow()),
              // Task list body.
              const _TaskListSliver(),
              // Bottom padding so FAB doesn't overlap last card.
              const SliverToBoxAdapter(child: SizedBox(height: 88)),
            ],
          ),
          const Positioned(
            right: AppSizes.lg,
            bottom: AppSizes.xl,
            child: _AddTaskFAB(),
          ),
        ],
      ),
    );
  }
}

// ── Android layout ────────────────────────────────────────────────────────────

class _AndroidMaintenanceLayout extends ConsumerWidget {
  const _AndroidMaintenanceLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      floatingActionButton: const _AddTaskFAB(),
      body: RefreshIndicator(
        color: AppColors.deepNavy,
        onRefresh: () =>
            ref.read(maintenanceTasksProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text('Tasks', style: AppTextStyles.h3),
              floating: true,
              backgroundColor: AppColors.warmOffWhite,
              scrolledUnderElevation: 0,
              elevation: 0,
              actions: [
                _SortButton(
                  isIOS: false,
                  onSortSelected: (order) => ref
                      .read(taskFilterProvider.notifier)
                      .setSortOrder(order),
                  onGenerateTasks: () => _generateTasks(ref),
                ),
              ],
            ),
            // Health score card.
            const SliverToBoxAdapter(child: HealthScoreWidget()),
            const SliverToBoxAdapter(child: _FilterRow()),
            const _TaskListSliver(),
            const SliverToBoxAdapter(child: SizedBox(height: AppSizes.xl)),
          ],
        ),
      ),
    );
  }
}

// ── Task list sliver ──────────────────────────────────────────────────────────

/// Builds the main content sliver — skeleton / error / empty / grouped list.
class _TaskListSliver extends ConsumerWidget {
  const _TaskListSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(maintenanceTasksProvider);
    return tasksAsync.when(
      loading: () => const SliverFillRemaining(child: TaskListSkeleton()),
      error: (e, _) => SliverFillRemaining(
        child: ErrorView(
          message: "Couldn't load tasks.",
          onRetry: () => ref.read(maintenanceTasksProvider.notifier).refresh(),
        ),
      ),
      data: (_) {
        final filtered = ref.watch(filteredTasksProvider);
        final filter = ref.watch(taskFilterProvider);
        final allTasks = ref.watch(maintenanceTasksProvider).value ?? [];

        // No tasks at all → motivational empty state.
        if (allTasks.isEmpty) {
          return SliverFillRemaining(
            child: TaskEmptyState(
              onAddSystem: () => context.push(AppRoutes.homeSystemsAdd),
            ),
          );
        }

        // Tasks exist but active filter returns nothing.
        if (filtered.isEmpty) {
          // All-tab with tasks but nothing due → celebration state.
          if (filter.statusFilter == null) {
            return const SliverFillRemaining(child: TaskCaughtUpState());
          }
          return const SliverFillRemaining(child: TaskFilterEmptyState());
        }

        // Build grouped list with section headers baked into a single SliverList.
        final items = _buildSectionedItems(filtered, filter);

        return SliverPadding(
          padding: AppPadding.screen,
          sliver: SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              if (item is _SectionHeader) {
                return Padding(
                  padding: const EdgeInsets.only(
                    top: AppSizes.md,
                    bottom: AppSizes.xs,
                  ),
                  child: Text(
                    item.title,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }
              if (item is _TaskItem) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.sm),
                  child: TaskCard(task: item.task),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  /// Interleaves [_SectionHeader] and [_TaskItem] records into a flat list.
  ///
  /// When a status filter is active, no section headers are shown — the filter
  /// chip itself communicates the grouping. Headers are only shown in "All".
  List<Object> _buildSectionedItems(
    List<MaintenanceTask> tasks,
    TaskFilter filter,
  ) {
    if (filter.statusFilter != null) {
      // Filtered view — flat list, no headers.
      return tasks.map((t) => _TaskItem(t)).toList();
    }

    // "All" view — group by urgency.
    final now = DateTime.now().toLocal();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final tomorrowMidnight = todayMidnight.add(const Duration(days: 1));
    final weekEnd = todayMidnight.add(const Duration(days: 7));

    final overdue = <MaintenanceTask>[];
    final dueToday = <MaintenanceTask>[];
    final thisWeek = <MaintenanceTask>[];
    final upcoming = <MaintenanceTask>[];
    final completed = <MaintenanceTask>[];

    for (final task in tasks) {
      final due = task.dueDate.toLocal();
      if (task.status == TaskStatus.completed ||
          task.status == TaskStatus.skipped) {
        completed.add(task);
      } else if (task.status == TaskStatus.overdue ||
          due.isBefore(todayMidnight)) {
        overdue.add(task);
      } else if (!due.isBefore(todayMidnight) &&
          due.isBefore(tomorrowMidnight)) {
        dueToday.add(task);
      } else if (due.isBefore(weekEnd)) {
        thisWeek.add(task);
      } else {
        upcoming.add(task);
      }
    }

    final result = <Object>[];

    void addSection(String title, List<MaintenanceTask> section) {
      if (section.isEmpty) return;
      result.add(_SectionHeader(title));
      result.addAll(section.map(_TaskItem.new));
    }

    addSection('Overdue', overdue);
    addSection('Due Today', dueToday);
    addSection(_thisWeekLabel(todayMidnight, weekEnd), thisWeek);
    addSection('Upcoming', upcoming);
    addSection('Completed', completed);

    return result;
  }

  String _thisWeekLabel(DateTime todayMidnight, DateTime weekEnd) {
    final fmt = DateFormat('MMM d');
    return 'This Week (${fmt.format(todayMidnight)} – ${fmt.format(weekEnd)})';
  }
}

// ── Section list item types ───────────────────────────────────────────────────

class _SectionHeader {
  const _SectionHeader(this.title);
  final String title;
}

class _TaskItem {
  const _TaskItem(this.task);
  final MaintenanceTask task;
}

// ── Filter chips row ──────────────────────────────────────────────────────────

class _FilterRow extends ConsumerWidget {
  const _FilterRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(taskFilterProvider);
    final notifier = ref.read(taskFilterProvider.notifier);

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: AppPadding.screenHorizontal,
        children: [
          _FilterChip(
            label: 'All',
            isSelected: filter.statusFilter == null,
            onTap: () => notifier.setStatusFilter(null),
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppSizes.sm),
            child: _FilterChip(
              label: 'Overdue',
              isSelected: filter.statusFilter == TaskStatusFilter.overdue,
              onTap: () => notifier.setStatusFilter(TaskStatusFilter.overdue),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppSizes.sm),
            child: _FilterChip(
              label: 'Due Soon',
              isSelected: filter.statusFilter == TaskStatusFilter.dueSoon,
              onTap: () => notifier.setStatusFilter(TaskStatusFilter.dueSoon),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppSizes.sm),
            child: _FilterChip(
              label: 'Upcoming',
              isSelected: filter.statusFilter == TaskStatusFilter.upcoming,
              onTap: () => notifier.setStatusFilter(TaskStatusFilter.upcoming),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppSizes.sm),
            child: _FilterChip(
              label: 'Completed',
              isSelected: filter.statusFilter == TaskStatusFilter.completed,
              onTap: () => notifier.setStatusFilter(TaskStatusFilter.completed),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.deepNavy : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.deepNavy : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? AppColors.textInverse : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ── Generate tasks helper ─────────────────────────────────────────────────────

/// Generates tasks from templates via the provider (client-side, no Edge
/// Function JWT required — mirrors the generate-maintenance-tasks function).
Future<void> _generateTasks(WidgetRef ref) async {
  await ref.read(maintenanceTasksProvider.notifier).generateFromTemplates();
}

// ── Sort button ───────────────────────────────────────────────────────────────

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.isIOS,
    required this.onSortSelected,
    required this.onGenerateTasks,
  });

  final bool isIOS;
  final void Function(TaskSortOrder order) onSortSelected;
  final VoidCallback onGenerateTasks;

  static const _options = [
    (label: 'Due Date', order: TaskSortOrder.dueDateAsc),
    (label: 'Priority', order: TaskSortOrder.priorityDesc),
    (label: 'Name', order: TaskSortOrder.nameAsc),
  ];

  @override
  Widget build(BuildContext context) {
    if (isIOS) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _showIOSSortSheet(context),
        child: const Icon(CupertinoIcons.sort_down),
      );
    }

    return PopupMenuButton<Object>(
      icon: const Icon(Icons.sort),
      color: AppColors.surface,
      onSelected: (value) {
        if (value is TaskSortOrder) {
          onSortSelected(value);
        } else if (value == 'generate') {
          onGenerateTasks();
        }
      },
      itemBuilder: (_) => [
        ..._options.map(
          (opt) => PopupMenuItem<Object>(
            value: opt.order,
            child: Text(opt.label, style: AppTextStyles.bodyMedium),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<Object>(
          value: 'generate',
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_outlined, size: 18),
              const SizedBox(width: AppSizes.sm),
              Text('Generate Tasks', style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showIOSSortSheet(BuildContext context) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Sort By'),
        actions: [
          ..._options.map(
            (opt) => CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                onSortSelected(opt.order);
              },
              child: Text(opt.label),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              onGenerateTasks();
            },
            child: const Text('Generate Tasks'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

// ── Add Task FAB ──────────────────────────────────────────────────────────────

/// Floating action button that opens the task creation form.
///
/// Rendered on both iOS (inside Stack overlay) and Android (Scaffold FAB).
class _AddTaskFAB extends StatelessWidget {
  const _AddTaskFAB();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => context.push(AppRoutes.maintenanceCreate),
      backgroundColor: AppColors.deepNavy,
      foregroundColor: AppColors.textInverse,
      elevation: 3,
      child: const Icon(Icons.add),
    );
  }
}
