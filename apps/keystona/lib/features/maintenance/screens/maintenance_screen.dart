import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../models/maintenance_task.dart';
import '../providers/maintenance_tasks_provider.dart';
import '../widgets/agenda_task_card.dart';
import '../widgets/by_system_view.dart';
import '../widgets/overdue_banner.dart';
import '../widgets/plan_view.dart';
import '../widgets/seasonal_view.dart';
import '../widgets/tip_card.dart';
import '../widgets/upcoming_peek.dart';
import '../widgets/week_strip.dart';

// ── View tab enum ──────────────────────────────────────────────────────────────

enum _TaskViewTab { daily, seasonal, bySystem, plan }

// ── Date helpers ───────────────────────────────────────────────────────────────

DateTime _mondayOf(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  return d.subtract(Duration(days: d.weekday - 1));
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// ── Root screen widget ─────────────────────────────────────────────────────────

/// Calendar-agenda view for the Maintenance/Tasks tab.
///
/// State: [_selectedDate] (day shown in agenda) and [_weekStart] (Monday of
/// displayed week). Both are purely local — no provider needed.
class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  late DateTime _selectedDate;
  late DateTime _weekStart;
  _TaskViewTab _tab = _TaskViewTab.daily;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDate = DateTime(today.year, today.month, today.day);
    _weekStart = _mondayOf(_selectedDate);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _prevWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
    });
  }

  void _selectDay(DateTime day) {
    setState(() => _selectedDate = day);
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return isIOS ? _buildIOS(context) : _buildAndroid(context);
  }

  // ── iOS layout ─────────────────────────────────────────────────────────────

  Widget _buildIOS(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.warmOffWhite,
      child: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              CupertinoSliverNavigationBar(
                middle: Text('Tasks', style: AppTextStyles.headlineSmall),
                trailing: _HeaderButtons(),
                backgroundColor: AppColors.warmOffWhite,
                border: const Border(),
              ),
              CupertinoSliverRefreshControl(
                onRefresh: () =>
                    ref.read(maintenanceTasksProvider.notifier).refresh(),
              ),
              _buildToggleSliver(),
              ..._currentSlivers(),
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
          Positioned(
            bottom: 110,
            right: 22,
            child: _AddTaskFAB(),
          ),
        ],
      ),
    );
  }

  // ── Android layout ──────────────────────────────────────────────────────────

  Widget _buildAndroid(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      floatingActionButton: _AddTaskFAB(),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () =>
            ref.read(maintenanceTasksProvider.notifier).refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              title: Text('Tasks', style: AppTextStyles.headlineSmall),
              floating: true,
              backgroundColor: AppColors.warmOffWhite,
              scrolledUnderElevation: 0,
              elevation: 0,
              actions: [_HeaderButtons()],
            ),
            _buildToggleSliver(),
            ..._currentSlivers(),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }

  // ── Toggle sliver ────────────────────────────────────────────────────────────

  Widget _buildToggleSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding, 4, AppSizes.screenPadding, 0,
        ),
        child: _ViewToggle(
          current: _tab,
          onChanged: (t) {
            setState(() => _tab = t);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _scrollController.hasClients) {
                _scrollController.jumpTo(0);
              }
            });
          },
        ),
      ),
    );
  }

  // ── Current view slivers ─────────────────────────────────────────────────────

  List<Widget> _currentSlivers() {
    switch (_tab) {
      case _TaskViewTab.daily:
        return [
          _buildCalendarHeader(),
          _buildTipSliver(),
          _buildDayHeaderSliver(),
          _buildOverdueBannerSliver(),
          _AgendaSliver(
            selectedDate: _selectedDate,
            onQuickComplete: (taskId) => ref
                .read(maintenanceTasksProvider.notifier)
                .completeTask(taskId),
          ),
          _buildUpcomingSliver(),
        ];
      case _TaskViewTab.seasonal:
        return [const SeasonalViewSliver()];
      case _TaskViewTab.bySystem:
        return [const BySystemViewSliver()];
      case _TaskViewTab.plan:
        return [const PlanViewSliver()];
    }
  }

  // ── Calendar header sliver ─────────────────────────────────────────────────

  Widget _buildCalendarHeader() {
    final tasksAsync = ref.watch(maintenanceTasksProvider);
    final tasks = tasksAsync.value ?? const <MaintenanceTask>[];
    final monthLabel = DateFormat('MMMM yyyy').format(_weekStart);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month nav row
            Row(
              children: [
                Text(
                  monthLabel,
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                _NavButton(
                  icon: Icons.chevron_left,
                  onTap: _prevWeek,
                ),
                const SizedBox(width: 6),
                _NavButton(
                  icon: Icons.chevron_right,
                  onTap: _nextWeek,
                ),
              ],
            ),
            const SizedBox(height: 12),
            WeekStrip(
              tasks: tasks,
              weekStart: _weekStart,
              selectedDate: _selectedDate,
              onDaySelected: _selectDay,
            ),
            const SizedBox(height: 12),
            const Divider(
              color: AppColors.border,
              thickness: 1.5,
              height: 1.5,
            ),
          ],
        ),
      ),
    );
  }

  // ── Day header sliver ──────────────────────────────────────────────────────

  Widget _buildDayHeaderSliver() {
    final tasksAsync = ref.watch(maintenanceTasksProvider);
    final tasks = tasksAsync.value ?? const <MaintenanceTask>[];
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);

    final isToday = _sameDay(_selectedDate, todayMidnight);
    final dayLabel = isToday
        ? 'Today, ${DateFormat('MMM d').format(_selectedDate)}'
        : DateFormat('EEE, MMM d').format(_selectedDate);

    // Count overdue and due-today tasks for the selected date.
    final overdue = tasks.where((t) {
      if (t.status == TaskStatus.completed ||
          t.status == TaskStatus.skipped) { return false; }
      final due = t.dueDate.toLocal();
      final dueMidnight = DateTime(due.year, due.month, due.day);
      return t.status == TaskStatus.overdue ||
          dueMidnight.isBefore(todayMidnight);
    }).length;

    final dueSel = tasks.where((t) {
      if (t.status == TaskStatus.completed ||
          t.status == TaskStatus.skipped) { return false; }
      return _sameDay(t.dueDate.toLocal(), _selectedDate);
    }).length;

    final subParts = <String>[];
    if (overdue > 0) { subParts.add('$overdue overdue'); }
    if (dueSel > 0) { subParts.add('$dueSel due'); }
    final sub = subParts.join(' · ');

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(
          top: 16,
          left: AppSizes.screenPadding,
          right: AppSizes.screenPadding,
          bottom: 12,
        ),
        child: Row(
          children: [
            Text(
              dayLabel,
              style: AppTextStyles.headlineMedium,
            ),
            if (sub.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                sub,
                style: AppTextStyles.monoLabel.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Overdue banner sliver ──────────────────────────────────────────────────

  Widget _buildOverdueBannerSliver() {
    final tasksAsync = ref.watch(maintenanceTasksProvider);
    final tasks = tasksAsync.value ?? const <MaintenanceTask>[];
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);

    final overdueTasks = tasks.where((t) {
      if (t.status == TaskStatus.completed ||
          t.status == TaskStatus.skipped) { return false; }
      final due = t.dueDate.toLocal();
      final dueMidnight = DateTime(due.year, due.month, due.day);
      return t.status == TaskStatus.overdue ||
          dueMidnight.isBefore(todayMidnight);
    }).toList();

    if (overdueTasks.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.screenPadding,
        ),
        child: OverdueBanner(overdueTasks: overdueTasks),
      ),
    );
  }

  // ── Tip card sliver ────────────────────────────────────────────────────────

  Widget _buildTipSliver() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: AppSizes.screenPadding,
          right: AppSizes.screenPadding,
        ),
        child: TipCard(),
      ),
    );
  }

  // ── Upcoming peek sliver ───────────────────────────────────────────────────

  Widget _buildUpcomingSliver() {
    final tasksAsync = ref.watch(maintenanceTasksProvider);
    final tasks = tasksAsync.value ?? const <MaintenanceTask>[];
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final weekEnd = todayMidnight.add(const Duration(days: 8));

    final upcoming = tasks.where((t) {
      if (t.status == TaskStatus.completed ||
          t.status == TaskStatus.skipped) { return false; }
      final due = t.dueDate.toLocal();
      final dueMidnight = DateTime(due.year, due.month, due.day);
      return dueMidnight.isAfter(todayMidnight) &&
          dueMidnight.isBefore(weekEnd);
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    if (upcoming.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(
          top: 18,
          left: AppSizes.screenPadding,
          right: AppSizes.screenPadding,
        ),
        child: UpcomingPeek(tasks: upcoming),
      ),
    );
  }
}

// ── Header buttons ─────────────────────────────────────────────────────────────

class _HeaderButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircleIconButton(
          icon: Icons.tune_outlined,
          onTap: () {}, // filter sheet — future implementation
        ),
        const SizedBox(width: 6),
        _CircleIconButton(
          icon: Icons.search,
          onTap: () {}, // search — future implementation
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A2A2420),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}

// ── Nav button ─────────────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }
}

// ── Agenda sliver ──────────────────────────────────────────────────────────────

/// Watches [maintenanceTasksProvider] and renders the agenda for [selectedDate].
class _AgendaSliver extends ConsumerWidget {
  const _AgendaSliver({
    required this.selectedDate,
    required this.onQuickComplete,
  });

  final DateTime selectedDate;
  final void Function(String taskId) onQuickComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(maintenanceTasksProvider);

    return tasksAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
          child: _AgendaSkeleton(),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
          child: ErrorView(
            message: "Couldn't load tasks.",
            onRetry: () =>
                ref.read(maintenanceTasksProvider.notifier).refresh(),
          ),
        ),
      ),
      data: (tasks) {
        final todayTasks = tasks.where((t) {
          if (t.status == TaskStatus.completed ||
              t.status == TaskStatus.skipped) { return false; }
          return _sameDay(t.dueDate.toLocal(), selectedDate);
        }).toList();

        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SCHEDULED TODAY',
                  style: AppTextStyles.monoSection,
                ),
                const SizedBox(height: 10),
                if (todayTasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Nothing scheduled for this day',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  )
                else
                  ...todayTasks.map(
                    (task) => AgendaTaskCard(
                      key: ValueKey(task.id),
                      task: task,
                      onQuickComplete: () => onQuickComplete(task.id),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Agenda skeleton ────────────────────────────────────────────────────────────

/// Column-based shimmer skeleton for the agenda loading state.
/// Uses Column (not ListView) so it works inside SliverToBoxAdapter.
class _AgendaSkeleton extends StatelessWidget {
  const _AgendaSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.gray200,
      highlightColor: AppColors.gray100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 10, width: 110, color: AppColors.gray200),
          const SizedBox(height: 10),
          _SkeletonAgendaCard(),
          const SizedBox(height: AppSizes.sm),
          _SkeletonAgendaCard(),
          const SizedBox(height: AppSizes.sm),
          _SkeletonAgendaCard(),
        ],
      ),
    );
  }
}

class _SkeletonAgendaCard extends StatelessWidget {
  const _SkeletonAgendaCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
      ),
      child: Row(
        children: [
          Container(width: 56, color: AppColors.gray200),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 13, width: double.infinity, color: AppColors.gray200),
                const SizedBox(height: 6),
                Container(height: 10, width: 140, color: AppColors.gray200),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

// ── View toggle ────────────────────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.current, required this.onChanged});

  final _TaskViewTab current;
  final ValueChanged<_TaskViewTab> onChanged;

  static const _labels = {
    _TaskViewTab.daily: 'Daily',
    _TaskViewTab.seasonal: 'Season',
    _TaskViewTab.bySystem: 'By System',
    _TaskViewTab.plan: 'Plan',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.warmFill,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Row(
        children: _TaskViewTab.values.map((tab) {
          final selected = tab == current;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: selected ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: selected
                      ? const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    _labels[tab]!,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Add Task FAB ───────────────────────────────────────────────────────────────

class _AddTaskFAB extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => context.push(AppRoutes.maintenanceCreate),
      backgroundColor: AppColors.accent,
      foregroundColor: AppColors.textInverse,
      elevation: 3,
      child: const Icon(Icons.add),
    );
  }
}
