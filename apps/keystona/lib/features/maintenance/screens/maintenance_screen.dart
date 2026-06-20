import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

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

import '../widgets/upcoming_peek.dart';
import '../widgets/week_strip.dart';

// ── View tab enum ──────────────────────────────────────────────────────────────

enum _TaskViewTab { today, plan, systems, seasonal }

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
  _TaskViewTab _tab = _TaskViewTab.today;
  int _tabIndex = 0;
  int _slideDirection = 1;
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
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenPadding, 12,
                  AppSizes.screenPadding, 0,
                ),
                child: Row(
                  children: [
                    Text('Tasks', style: AppTextStyles.headlineMedium),
                    const Spacer(),
                    _HeaderButtons(),
                  ],
                ),
              ),
            ),
          ),
          _buildToggleSliver(),
          _buildAnimatedTabSliver(),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }

  // ── Android layout ──────────────────────────────────────────────────────────

  Widget _buildAndroid(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
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
            _buildAnimatedTabSliver(),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }

  // ── Tab strip sliver ─────────────────────────────────────────────────────────

  Widget _buildToggleSliver() {
    return SliverToBoxAdapter(
      child: _TabStrip(
        current: _tab,
        onChanged: (t) {
          HapticFeedback.selectionClick();
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }
          final newIndex = _TaskViewTab.values.indexOf(t);
          setState(() {
            _slideDirection = newIndex > _tabIndex ? 1 : -1;
            _tabIndex = newIndex;
            _tab = t;
          });
        },
      ),
    );
  }

  // ── Animated tab content ──────────────────────────────────────────────────────

  Widget _buildTabContent() {
    return switch (_tab) {
      _TaskViewTab.today => _buildDailyContent(),
      _TaskViewTab.plan => const PlanView(),
      _TaskViewTab.systems => const BySystemView(),
      _TaskViewTab.seasonal => const SeasonalView(),
    };
  }

  Widget _buildDailyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCalendarHeader(),
        _buildDayHeader(),
        _buildOverdueBanner(),
        _AgendaWidget(
          selectedDate: _selectedDate,
          onQuickComplete: (taskId) =>
              ref.read(maintenanceTasksProvider.notifier).completeTask(taskId),
        ),
        _buildUpcoming(),
      ],
    );
  }

  SliverToBoxAdapter _buildAnimatedTabSliver() {
    return SliverToBoxAdapter(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        // Top-align children so the incoming tab never appears vertically
        // centered inside a taller outgoing tab's layout box.
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.topCenter,
          children: [
            ...previousChildren,
            ?currentChild,
          ],
        ),
        transitionBuilder: (child, animation) {
          final isIncoming =
              (child.key as ValueKey?)?.value == _tabIndex;
          if (isIncoming) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0.06 * _slideDirection, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOut)),
              child: FadeTransition(opacity: animation, child: child),
            );
          }
          return FadeTransition(opacity: animation, child: child);
        },
        child: KeyedSubtree(
          key: ValueKey(_tabIndex),
          child: _buildTabContent(),
        ),
      ),
    );
  }

  // ── Daily tab content helpers ──────────────────────────────────────────────

  Widget _buildCalendarHeader() {
    final tasksAsync = ref.watch(maintenanceTasksProvider);
    final tasks = tasksAsync.value ?? const <MaintenanceTask>[];
    final monthLabel = DateFormat('MMMM yyyy').format(_weekStart);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenPadding, 14, AppSizes.screenPadding, 0,
          ),
            child: Row(
              children: [
                Text(
                  monthLabel,
                  style: AppTextStyles.bodyMediumSemibold.copyWith(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                _NavButton(icon: Icons.chevron_left, onTap: _prevWeek),
                const SizedBox(width: 6),
                _NavButton(icon: Icons.chevron_right, onTap: _nextWeek),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
            child: WeekStrip(
              tasks: tasks,
              weekStart: _weekStart,
              selectedDate: _selectedDate,
              onDaySelected: _selectDay,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border, thickness: 1, height: 1),
        ],
      );
  }

  Widget _buildDayHeader() {
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

    return Padding(
      padding: const EdgeInsets.only(
        top: 14,
        left: AppSizes.screenPadding,
        right: AppSizes.screenPadding,
        bottom: 10,
      ),
      child: Row(
        children: [
          Text(dayLabel, style: AppTextStyles.headlineMedium),
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
    );
  }

  Widget _buildOverdueBanner() {
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

    if (overdueTasks.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
      child: OverdueBanner(overdueTasks: overdueTasks),
    );
  }

  Widget _buildUpcoming() {
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

    if (upcoming.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(
        top: 18,
        left: AppSizes.screenPadding,
        right: AppSizes.screenPadding,
      ),
      child: UpcomingPeek(tasks: upcoming),
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
              color: AppColors.shadowXs,
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

// ── Agenda widget ──────────────────────────────────────────────────────────────

class _AgendaWidget extends ConsumerWidget {
  const _AgendaWidget({
    required this.selectedDate,
    required this.onQuickComplete,
  });

  final DateTime selectedDate;
  final void Function(String taskId) onQuickComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(maintenanceTasksProvider);

    return tasksAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
        child: _AgendaSkeleton(),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
        child: ErrorView(
          message: "Couldn't load tasks.",
          onRetry: () =>
              ref.read(maintenanceTasksProvider.notifier).refresh(),
        ),
      ),
      data: (tasks) {
        final todayTasks = tasks.where((t) {
          if (!t.notificationsEnabled) return false;
          if (t.status == TaskStatus.completed ||
              t.status == TaskStatus.skipped) {
            return false;
          }
          return _sameDay(t.dueDate.toLocal(), selectedDate);
        }).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    showDate: !_sameDay(selectedDate, DateTime.now()),
                  ),
                ),
            ],
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

// ── Tab strip ──────────────────────────────────────────────────────────────────

class _TabStrip extends StatelessWidget {
  const _TabStrip({required this.current, required this.onChanged});

  final _TaskViewTab current;
  final ValueChanged<_TaskViewTab> onChanged;

  static const _labels = {
    _TaskViewTab.today: 'Today',
    _TaskViewTab.plan: 'Plan',
    _TaskViewTab.systems: 'Systems',
    _TaskViewTab.seasonal: 'Seasonal',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
        child: Row(
          children: _TaskViewTab.values.map((tab) {
            final selected = tab == current;
            return GestureDetector(
              onTap: () => onChanged(tab),
              behavior: HitTestBehavior.opaque,
              child: Container(
                margin: const EdgeInsets.only(right: 28),
                padding: const EdgeInsets.only(top: 6, bottom: 11),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected ? AppColors.accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  _labels[tab]!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

