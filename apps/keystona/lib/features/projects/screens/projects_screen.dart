import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/upgrade_sheet.dart';
import '../../../services/providers/service_providers.dart';
import '../../subscription/providers/subscription_provider.dart';
import '../models/project.dart';
import '../providers/projects_provider.dart';
import '../widgets/project_card.dart';
import '../widgets/project_empty_state.dart';
import '../widgets/project_list_skeleton.dart';

enum _ViewMode { board, list }

/// Projects list screen — Tab 3.
class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  String? _activeFilter;
  _ViewMode _viewMode = _ViewMode.board;

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final asyncData = ref.watch(projectsProvider);

    return asyncData.when(
      loading: () => _shell(
        isIOS: isIOS,
        projectCount: 0,
        slivers: [
          SliverToBoxAdapter(
            child: _ProjectsHeader(
              totalCount: 0,
              activeCount: 0,
              onAdd: _onCreateTap,
            ),
          ),
          const SliverFillRemaining(
            hasScrollBody: true,
            child: ProjectListSkeleton(),
          ),
        ],
      ),
      error: (e, _) => _shell(
        isIOS: isIOS,
        projectCount: 0,
        slivers: [
          SliverToBoxAdapter(
            child: _ProjectsHeader(
              totalCount: 0,
              activeCount: 0,
              onAdd: _onCreateTap,
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: _ErrorState(onRetry: () => ref.invalidate(projectsProvider)),
          ),
        ],
      ),
      data: (projects) {
        final activeCount = projects
            .where((p) => p.status == 'in_progress' || p.status == 'planning')
            .length;
        final filtered = _activeFilter == null
            ? projects
            : projects.where((p) => p.status == _activeFilter).toList();

        return _shell(
          isIOS: isIOS,
          projectCount: projects.length,
          slivers: [
            SliverToBoxAdapter(
              child: _ProjectsHeader(
                totalCount: projects.length,
                activeCount: activeCount,
                onAdd: _onCreateTap,
              ),
            ),
            if (projects.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ProjectEmptyState(onCreateProject: _onCreateTap),
              )
            else ...[
              _BudgetRibbon.sliver(projects),
              SliverToBoxAdapter(
                child: _ViewToggle(
                  mode: _viewMode,
                  onChanged: (m) => setState(() {
                    _viewMode = m;
                    _activeFilter = null;
                  }),
                ),
              ),
              if (_viewMode == _ViewMode.board)
                SliverToBoxAdapter(
                  child: _BoardView(
                    projects: projects,
                    onTap: (id) => context.push(
                      AppRoutes.projectDetail.replaceFirst(':projectId', id),
                    ),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: _FilterChips(
                    activeFilter: _activeFilter,
                    onChanged: (f) => setState(() => _activeFilter = f),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _NoResultsState(
                      filter: _activeFilter,
                      onClear: () => setState(() => _activeFilter = null),
                    ),
                  )
                else
                  SliverPadding(
                    padding: AppPadding.screen.copyWith(top: AppSizes.sm),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSizes.sm),
                      itemBuilder: (ctx, i) => ProjectCard(
                        project: filtered[i],
                        onTap: () => ctx.push(
                          AppRoutes.projectDetail.replaceFirst(
                            ':projectId',
                            filtered[i].id,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSizes.xxl + AppSizes.xl),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _shell({
    required bool isIOS,
    required int projectCount,
    required List<Widget> slivers,
  }) {
    final scrollView = CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () => ref.read(projectsProvider.notifier).refresh(),
        ),
        ...slivers,
      ],
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        child: SafeArea(
          bottom: false,
          child: projectCount > 0
              ? Stack(
                  children: [
                    scrollView,
                    Positioned(
                      bottom: AppSizes.lg,
                      right: AppSizes.md,
                      child: _FAB(
                        onTap: _onCreateTap,
                        projectCount: projectCount,
                      ),
                    ),
                  ],
                )
              : scrollView,
        ),
      );
    }

    return Scaffold(
      body: SafeArea(bottom: false, child: scrollView),
      floatingActionButton: projectCount > 0
          ? FloatingActionButton(
              onPressed: _onCreateTap,
              backgroundColor: AppColors.accent,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Future<void> _onCreateTap() async {
    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium) {
      final projects = ref.read(projectsProvider).value ?? [];
      if (projects.length >= kFreeProjectLimit) {
        if (!mounted) return;
        await UpgradeSheet.show(
          context,
          config: const UpgradeSheetConfig(
            headline: 'Unlock Unlimited Projects',
            reason: 'Free accounts are limited to 2 active projects.',
            features: [
              'Unlimited home improvement projects',
              'Full budget tracking',
              'Before & after photo comparisons',
              'Contractor management',
            ],
            triggerKey: 'project_limit',
          ),
        );
        return;
      }
    }
    if (!mounted) return;
    context.push(AppRoutes.projectsCreate);
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ProjectsHeader extends StatelessWidget {
  const _ProjectsHeader({
    required this.totalCount,
    required this.activeCount,
    required this.onAdd,
  });

  final int totalCount;
  final int activeCount;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.lg,
        AppSizes.md,
        AppSizes.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Projects', style: AppTextStyles.displayLarge),
              if (totalCount > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '$totalCount ${totalCount == 1 ? 'project' : 'projects'} · $activeCount active',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
          _AddButton(onTap: onAdd),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.add, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}

// ── View toggle ───────────────────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.mode, required this.onChanged});

  final _ViewMode mode;
  final ValueChanged<_ViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.xs,
        AppSizes.md,
        AppSizes.sm,
      ),
      child: Row(
        children: [
          Text(
            mode == _ViewMode.board ? 'Board view' : 'List view',
            style: AppTextStyles.headlineSmall,
          ),
          const Spacer(),
          _SegmentedControl(mode: mode, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({required this.mode, required this.onChanged});

  final _ViewMode mode;
  final ValueChanged<_ViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.warmFill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            label: 'Board',
            active: mode == _ViewMode.board,
            onTap: () => onChanged(_ViewMode.board),
          ),
          _Segment(
            label: 'List',
            active: mode == _ViewMode.list,
            onTap: () => onChanged(_ViewMode.list),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: active ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Board view ────────────────────────────────────────────────────────────────

class _BoardView extends StatelessWidget {
  const _BoardView({required this.projects, required this.onTap});

  final List<Project> projects;
  final ValueChanged<String> onTap;

  static const _lanes = [
    (status: 'in_progress', label: 'IN PROGRESS', color: AppColors.slate,  laneHeight: 220.0),
    (status: 'planning',    label: 'PLANNING',    color: AppColors.sand,   laneHeight: 220.0),
    (status: 'on_hold',     label: 'ON HOLD',     color: AppColors.amber,  laneHeight: 220.0),
    (status: 'completed',   label: 'COMPLETED',   color: AppColors.olive,  laneHeight: 76.0),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final lane in _lanes)
          _Lane(
            label: lane.label,
            color: lane.color,
            laneHeight: lane.laneHeight,
            projects: projects
                .where((p) => p.status == lane.status)
                .toList(),
            onTap: onTap,
          ),
      ],
    );
  }
}

class _Lane extends StatelessWidget {
  const _Lane({
    required this.label,
    required this.color,
    required this.laneHeight,
    required this.projects,
    required this.onTap,
  });

  final String label;
  final Color color;
  final double laneHeight;
  final List<Project> projects;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top divider
        Container(height: 1, color: AppColors.warmFill),

        // Lane header
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.md,
            14,
            AppSizes.md,
            10,
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                label,
                style: AppTextStyles.monoSection.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 9),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${projects.length}',
                  style: AppTextStyles.monoTiny.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),

        // Horizontal tile scroll
        SizedBox(
          height: laneHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(
              left: AppSizes.md,
              right: AppSizes.lg,
            ),
            itemCount: projects.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) => SizedBox(
              width: 265,
              child: ProjectCard(
                project: projects[i],
                onTap: () => onTap(projects[i].id),
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSizes.md),
      ],
    );
  }
}

// ── Filter chips ──────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.activeFilter,
    required this.onChanged,
  });

  final String? activeFilter;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      child: Row(
        children: [
          _Chip(
            label: 'All',
            selected: activeFilter == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: AppSizes.xs),
          for (final s in ProjectStatuses.all)
            Padding(
              padding: const EdgeInsets.only(left: AppSizes.xs),
              child: _Chip(
                label: s.label,
                selected: activeFilter == s.value,
                onTap: () => onChanged(
                  activeFilter == s.value ? null : s.value,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.deepNavy : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: selected ? AppColors.deepNavy : AppColors.gray300,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── FAB (iOS) ─────────────────────────────────────────────────────────────────

class _FAB extends StatelessWidget {
  const _FAB({required this.onTap, required this.projectCount});

  final VoidCallback onTap;
  final int projectCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: AppColors.deepNavy,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ── Budget ribbon ─────────────────────────────────────────────────────────────

class _BudgetRibbon extends StatelessWidget {
  const _BudgetRibbon({
    required this.totalBudget,
    required this.totalSpent,
  });

  final double totalBudget;
  final double totalSpent;

  /// Returns an empty sliver when no projects have budgets.
  static Widget sliver(List<Project> projects) {
    final withBudget = projects.where((p) => p.estimatedBudget != null);
    if (withBudget.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    final total = withBudget.fold(0.0, (s, p) => s + p.estimatedBudget!);
    final spent = projects.fold(0.0, (s, p) => s + p.actualSpent);
    return SliverToBoxAdapter(
      child: _BudgetRibbon(totalBudget: total, totalSpent: spent),
    );
  }

  static String _fmt(double v) {
    if (v >= 1000) {
      final k = v / 1000;
      return '\$${k % 1 == 0 ? k.toInt().toString() : k.toStringAsFixed(1)}k';
    }
    return '\$${NumberFormat('#,###').format(v.toInt())}';
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (totalBudget - totalSpent).clamp(0.0, double.infinity);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.xs,
        AppSizes.md,
        AppSizes.sm,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Base dark fill
            Container(
              color: AppColors.deepNavy,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              child: Row(
                children: [
                  _StatItem(
                    label: 'TOTAL BUDGET',
                    value: _fmt(totalBudget),
                    valueColor: AppColors.darkText,
                  ),
                  _VertDivider(),
                  _StatItem(
                    label: 'SPENT',
                    value: _fmt(totalSpent),
                    valueColor: AppColors.accent,
                  ),
                  _VertDivider(),
                  _StatItem(
                    label: 'REMAINING',
                    value: _fmt(remaining),
                    valueColor: AppColors.oliveLight,
                  ),
                ],
              ),
            ),
            // Radial warm tint — top-right decorative
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topRight,
                      radius: 1.0,
                      colors: [
                        AppColors.accent.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
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

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.monoSection.copyWith(
              color: AppColors.darkText.withValues(alpha: 0.4),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: AppTextStyles.monoDisplay.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: Colors.white.withValues(alpha: 0.10),
    );
  }
}

// ── No results (filtered) ─────────────────────────────────────────────────────

class _NoResultsState extends StatelessWidget {
  const _NoResultsState({required this.filter, required this.onClear});

  final String? filter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppPadding.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_off,
              size: AppSizes.iconXl,
              color: AppColors.gray400,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'No ${filter?.statusLabel ?? ''} projects',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),
            TextButton(
              onPressed: onClear,
              child: Text(
                'Clear filter',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.deepNavy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppPadding.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: AppSizes.xxl, color: AppColors.error),
            const SizedBox(height: AppSizes.md),
            Text(
              'Couldn\'t load projects',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.lg),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
