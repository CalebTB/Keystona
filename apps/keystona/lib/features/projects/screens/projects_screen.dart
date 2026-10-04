import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/widgets/aurora/aurora.dart';
import '../../../core/widgets/empty_state.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/upgrade_sheet.dart';
import '../../../services/providers/service_providers.dart';
import '../../subscription/providers/subscription_provider.dart';
import '../models/project.dart';
import '../providers/project_phases_provider.dart';
import '../providers/projects_provider.dart';
import '../widgets/project_empty_state.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _compactBudget(double v) {
  if (v >= 1_000_000) {
    final m = v / 1_000_000;
    return '\$${m % 1 == 0 ? m.toInt() : m.toStringAsFixed(1)}m';
  }
  if (v >= 1000) {
    final k = v / 1000;
    return '\$${k % 1 == 0 ? k.toInt() : k.toStringAsFixed(1)}k';
  }
  return '\$${NumberFormat('#,###').format(v.toInt())}';
}

String _shortDate(DateTime d) =>
    DateFormat('MMM d').format(d).toUpperCase();

// ── Screen ────────────────────────────────────────────────────────────────────

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  String? _activeFilter;

  void _onFilterChanged(String? value) {
    setState(() {
      _activeFilter =
          (value != null && value == _activeFilter) ? null : value;
    });
  }

  Future<void> _onRefresh() async {
    ref.invalidate(projectsProvider);
    await ref.read(projectsProvider.future).catchError((_) => <Project>[]);
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final asyncData = ref.watch(projectsProvider);

    return asyncData.when(
      loading: () => _wrapScaffold(
        isIOS: isIOS,
        child: const _ProjectsScreenSkeleton(),
        onCreateTap: _onCreateTap,
      ),
      error: (_, _) => _wrapScaffold(
        isIOS: isIOS,
        child: _ErrorState(onRetry: () => ref.invalidate(projectsProvider)),
        onCreateTap: _onCreateTap,
      ),
      data: (projects) {
        if (projects.isEmpty) {
          return _wrapScaffold(
            isIOS: isIOS,
            child: ProjectEmptyState(onCreateProject: _onCreateTap),
            onCreateTap: _onCreateTap,
          );
        }
        return _wrapScaffold(
          isIOS: isIOS,
          child: _ContentView(
            projects: projects,
            activeFilter: _activeFilter,
            onFilterChanged: _onFilterChanged,
            onRefresh: _onRefresh,
          ),
          onCreateTap: _onCreateTap,
        );
      },
    );
  }

  Widget _wrapScaffold({
    required bool isIOS,
    required Widget child,
    required VoidCallback onCreateTap,
  }) {
    final fab = _FabButton(onTap: onCreateTap);

    if (isIOS) {
      return CupertinoPageScaffold(
        backgroundColor: AuroraColors.paper,
        child: Stack(
          children: [
            SafeArea(bottom: false, child: child),
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              right: 16,
              child: fab,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AuroraColors.paper,
      floatingActionButton: fab,
      body: SafeArea(bottom: false, child: child),
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

// ── Content view ──────────────────────────────────────────────────────────────

class _ContentView extends StatelessWidget {
  const _ContentView({
    required this.projects,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.onRefresh,
  });

  final List<Project> projects;
  final String? activeFilter;
  final void Function(String?) onFilterChanged;
  final Future<void> Function() onRefresh;

  List<Project> _section(String status) =>
      projects.where((p) => p.status == status).toList();

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    final inProgress = _section('in_progress');
    final planning = _section('planning')
      ..sort((a, b) {
        final aDate = a.plannedStartDate;
        final bDate = b.plannedStartDate;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      });
    final onHold = _section('on_hold');
    final completed = _section('completed')
      ..sort((a, b) {
        final aDate = a.actualEndDate ?? a.plannedEndDate;
        final bDate = b.actualEndDate ?? b.plannedEndDate;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

    final totalCommitted =
        projects.fold(0.0, (s, p) => s + (p.estimatedBudget ?? 0));
    final displayCount =
        projects.where((p) => p.status != 'cancelled').length;

    // Build filtered section(s)
    List<Widget> sectionSlivers;

    if (activeFilter != null) {
      final list = _section(activeFilter!);
      if (list.isEmpty) {
        sectionSlivers = [
          SliverFillRemaining(
            child: _NoResultsState(
              filter: activeFilter,
              onClear: () => onFilterChanged(null),
            ),
          ),
        ];
      } else {
        sectionSlivers = [
          _SectionHeader(status: activeFilter!, count: list.length),
          _ProjectSectionSliver(projects: list),
        ];
      }
    } else {
      sectionSlivers = [
        if (inProgress.isNotEmpty) ...[
          _SectionHeader(status: 'in_progress', count: inProgress.length),
          _ProjectSectionSliver(projects: inProgress),
        ],
        if (planning.isNotEmpty) ...[
          _SectionHeader(status: 'planning', count: planning.length),
          _ProjectSectionSliver(projects: planning),
        ],
        if (onHold.isNotEmpty) ...[
          _SectionHeader(status: 'on_hold', count: onHold.length),
          _ProjectSectionSliver(projects: onHold),
        ],
        if (completed.isNotEmpty) ...[
          _SectionHeader(status: 'completed', count: completed.length),
          _ProjectSectionSliver(projects: completed),
        ],
      ];
    }

    final scrollView = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (isIOS)
          CupertinoSliverRefreshControl(onRefresh: onRefresh),
        SliverToBoxAdapter(
          child: _Header(
            totalCount: displayCount,
            totalCommitted: totalCommitted,
          ),
        ),
        SliverToBoxAdapter(
          child: _FilterChips(
            projects: projects,
            activeFilter: activeFilter,
            onChanged: onFilterChanged,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AuroraSpacing.space3)),
        ...sectionSlivers,
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );

    if (isIOS) return scrollView;

    return RefreshIndicator(
      color: AuroraColors.coral,
      onRefresh: onRefresh,
      child: scrollView,
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.totalCount, required this.totalCommitted});

  final int totalCount;
  final double totalCommitted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AuroraColors.coral,
                ),
              ),
              const SizedBox(width: AuroraSpacing.space2),
              Text(
                'PROJECTS · $totalCount TOTAL',
                style: AuroraType.labelSm.copyWith(
                  color: AuroraColors.coral,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AuroraSpacing.space2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'Your renovations.',
                  style: AuroraType.h1.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (totalCommitted > 0)
                Text(
                  _compactBudget(totalCommitted),
                  style: AuroraType.h3.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AuroraColors.ink,
                    letterSpacing: -0.3,
                  ),
                ),
            ],
          ),
          if (totalCommitted > 0) ...[
            const SizedBox(height: AuroraSpacing.space1),
            Text(
              '${_compactBudget(totalCommitted)} committed across $totalCount projects',
              style: AuroraType.bodySm.copyWith(
                color: const Color(0xFF9D9BB0),
              ),
            ),
          ],
          const SizedBox(height: AuroraSpacing.space1),
        ],
      ),
    );
  }
}

// ── Filter chips ──────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.projects,
    required this.activeFilter,
    required this.onChanged,
  });

  final List<Project> projects;
  final String? activeFilter;
  final void Function(String?) onChanged;

  static const _filters = [
    (value: null, label: 'All'),
    (value: 'in_progress', label: 'In Progress'),
    (value: 'planning', label: 'Planning'),
    (value: 'on_hold', label: 'On Hold'),
    (value: 'completed', label: 'Completed'),
  ];

  int _count(String? status) => status == null
      ? projects.where((p) => p.status != 'cancelled').length
      : projects.where((p) => p.status == status).length;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          for (int i = 0; i < _filters.length; i++) ...[
            if (i > 0) const SizedBox(width: AuroraSpacing.space3),
            _Chip(
              label: _filters[i].label,
              count: _count(_filters[i].value),
              selected: activeFilter == _filters[i].value,
              onTap: () => onChanged(_filters[i].value),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AuroraColors.ink : Colors.transparent,
          borderRadius: AuroraRadius.full,
          border: Border.all(
            color: selected ? AuroraColors.ink : AuroraColors.inkBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AuroraType.label.copyWith(
                fontWeight: FontWeight.w600,
                color: selected
                    ? AuroraColors.paper
                    : AuroraColors.inkSecondary,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? AuroraColors.paper.withValues(alpha: 0.18)
                    : AuroraColors.butter,
                borderRadius: AuroraRadius.sm,
              ),
              child: Text(
                '$count',
                style: AuroraType.labelSm.copyWith(
                  color: selected
                      ? AuroraColors.paper.withValues(alpha: 0.85)
                      : AuroraColors.inkSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.status, required this.count});

  final String status;
  final int count;

  static ({Color dot, String label, String right}) _props(
      String status, int count) =>
      switch (status) {
        'in_progress' => (
            dot: AuroraColors.coral,
            label: 'IN PROGRESS',
            right: '$count active',
          ),
        'planning' => (
            dot: AuroraColors.cobalt,
            label: 'PLANNING',
            right: '$count project${count == 1 ? '' : 's'}',
          ),
        'on_hold' => (
            dot: AuroraColors.yellow,
            label: 'ON HOLD',
            right: '$count paused',
          ),
        'completed' => (
            dot: AuroraColors.limeDeep,
            label: 'COMPLETED',
            right: '$count done',
          ),
        _ => (
            dot: AuroraColors.inkTertiary,
            label: status.toUpperCase(),
            right: '$count',
          ),
      };

  @override
  Widget build(BuildContext context) {
    final p = _props(status, count);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.dot,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              p.label,
              style: AuroraType.labelSm.copyWith(
                color: const Color(0xFF9D9BB0),
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              p.right,
              style: AuroraType.labelSm.copyWith(
                color: const Color(0xFF9D9BB0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Project section sliver ────────────────────────────────────────────────────

class _ProjectSectionSliver extends StatelessWidget {
  const _ProjectSectionSliver({required this.projects});
  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.separated(
        itemCount: projects.length,
        separatorBuilder: (_, _) => const SizedBox(height: AuroraSpacing.space3),
        itemBuilder: (ctx, i) => _ProjectCard(
          project: projects[i],
          onTap: () => ctx.push(
            AppRoutes.projectDetail
                .replaceFirst(':projectId', projects[i].id),
          ),
        ),
      ),
    );
  }
}

// ── Project card ──────────────────────────────────────────────────────────────

class _ProjectCard extends ConsumerWidget {
  const _ProjectCard({required this.project, required this.onTap});

  final Project project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phasesAsync = ref.watch(projectPhasesProvider(project.id));
    final phases = phasesAsync.value
            ?.where((p) => p.status != 'cancelled' && p.deletedAt == null)
            .toList() ??
        [];

    final total =
        phases.isNotEmpty ? phases.length : project.phaseCount;
    final done =
        phases.where((p) => p.status == 'completed').length;
    final active =
        phases.where((p) => p.status == 'in_progress').length;
    final phasesLoaded = phases.isNotEmpty;

    final completionPct = total > 0 && phasesLoaded
        ? (done / total).clamp(0.0, 1.0)
        : (project.status == 'completed' ? 1.0 : 0.0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AuroraColors.paper,
          borderRadius: AuroraRadius.md,
          border: Border.all(color: AuroraColors.inkBorder),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProjectThumbnail(projectType: project.projectType),
            const SizedBox(width: AuroraSpacing.space5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          project.name,
                          style: AuroraType.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AuroraColors.ink,
                          ),
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(width: AuroraSpacing.space3),
                      _StatusChip(status: project.status),
                    ],
                  ),
                  const SizedBox(height: 5),
                  _MetaLine(
                    project: project,
                    total: total,
                    done: done,
                    active: active,
                    phasesLoaded: phasesLoaded,
                  ),
                  const SizedBox(height: AuroraSpacing.space3),
                  _ProgressBar(
                    value: completionPct,
                    status: project.status,
                  ),
                  const SizedBox(height: AuroraSpacing.space2),
                  _BudgetRow(
                    project: project,
                    completionPct: completionPct,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Project thumbnail ─────────────────────────────────────────────────────────

typedef _TypeVisual = ({IconData icon, Color bg, Color fg});

class _ProjectThumbnail extends StatelessWidget {
  const _ProjectThumbnail({required this.projectType});
  final String projectType;

  static _TypeVisual _visual(String type) => switch (type) {
        'kitchen_remodel' => (
            icon: Icons.restaurant_outlined,
            bg: Color(0x1FFF3B62),
            fg: AuroraColors.coral,
          ),
        'bathroom_remodel' || 'plumbing' => (
            icon: Icons.water_drop_outlined,
            bg: AuroraColors.cobaltDim,
            fg: AuroraColors.cobalt,
          ),
        'deck_build' => (
            icon: Icons.stairs_outlined,
            bg: Color(0x33FFD947),
            fg: Color(0xFFB8860B),
          ),
        'painting' => (
            icon: Icons.format_paint_outlined,
            bg: AuroraColors.butter,
            fg: AuroraColors.inkSecondary,
          ),
        'roofing' => (
            icon: Icons.home_outlined,
            bg: AuroraColors.cobaltDim,
            fg: AuroraColors.cobalt,
          ),
        'flooring' => (
            icon: Icons.grid_on_outlined,
            bg: Color(0x26FFD947),
            fg: Color(0xFFB8860B),
          ),
        'landscaping' => (
            icon: Icons.yard_outlined,
            bg: Color(0x26ECF87F),
            fg: AuroraColors.limeDeep,
          ),
        'hvac_replacement' => (
            icon: Icons.air_outlined,
            bg: AuroraColors.cobaltDim,
            fg: AuroraColors.cobalt,
          ),
        'electrical' => (
            icon: Icons.bolt_outlined,
            bg: Color(0x33FFD947),
            fg: Color(0xFFB8860B),
          ),
        'addition' || 'general_renovation' => (
            icon: Icons.home_work_outlined,
            bg: AuroraColors.butter,
            fg: AuroraColors.inkSecondary,
          ),
        _ => (
            icon: Icons.construction_outlined,
            bg: AuroraColors.butter,
            fg: AuroraColors.inkSecondary,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final v = _visual(projectType);
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: v.bg,
        borderRadius: AuroraRadius.sm,
      ),
      child: Icon(v.icon, size: 30, color: v.fg),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  static ({Color bg, Color fg, String label}) _props(String status) =>
      switch (status) {
        'in_progress' => (
            bg: Color(0x1FFF3B62),
            fg: AuroraColors.coral,
            label: 'ACTIVE',
          ),
        'planning' => (
            bg: AuroraColors.cobaltDim,
            fg: AuroraColors.cobalt,
            label: 'PLANNING',
          ),
        'on_hold' => (
            bg: AuroraColors.yellowDim,
            fg: Color(0xFFB8860B),
            label: 'ON HOLD',
          ),
        'completed' => (
            bg: AuroraColors.lime,
            fg: AuroraColors.limeDeep,
            label: 'DONE',
          ),
        'cancelled' => (
            bg: AuroraColors.butter,
            fg: AuroraColors.inkTertiary,
            label: 'CANCELLED',
          ),
        _ => (
            bg: AuroraColors.butter,
            fg: AuroraColors.inkSecondary,
            label: status.toUpperCase(),
          ),
      };

  @override
  Widget build(BuildContext context) {
    final p = _props(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: AuroraRadius.xs,
      ),
      child: Text(
        p.label,
        style: AuroraType.labelSm.copyWith(
          color: p.fg,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── Meta line ─────────────────────────────────────────────────────────────────

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.project,
    required this.total,
    required this.done,
    required this.active,
    required this.phasesLoaded,
  });

  final Project project;
  final int total;
  final int done;
  final int active;
  final bool phasesLoaded;

  String _text() {
    switch (project.status) {
      case 'in_progress':
        final parts = [
          if (total > 0) '$total PHASES',
          if (phasesLoaded && done > 0) '$done DONE',
          if (phasesLoaded && active > 0) '$active ACTIVE',
        ];
        return parts.join(' · ');
      case 'planning':
        final start = project.plannedStartDate ?? project.actualStartDate;
        final datePart = start != null
            ? ' · ESTIMATED START ${_shortDate(start)}'
            : '';
        return '${total > 0 ? '$total PHASES' : 'No phases'}$datePart';
      case 'on_hold':
        return '${total > 0 ? '$total PHASES' : 'No phases'} · PAUSED';
      case 'completed':
        final end = project.actualEndDate ?? project.plannedEndDate;
        final datePart = end != null ? 'FINISHED ${_shortDate(end)} · ' : '';
        return '$datePart${total > 0 ? '$total PHASES' : 'No phases'}';
      default:
        return total > 0 ? '$total PHASES' : '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _text(),
      style: AuroraType.labelSm.copyWith(
        color: const Color(0xFF9D9BB0),
        letterSpacing: 0.2,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ── Progress bar ──────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.status});

  final double value;
  final String status;

  Color _barColor() => switch (status) {
        'in_progress' => AuroraColors.coral,
        'planning' => AuroraColors.cobalt,
        'on_hold' => AuroraColors.yellow,
        'completed' => AuroraColors.limeDeep,
        _ => AuroraColors.inkBorderStrong,
      };

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AuroraRadius.xs,
      child: LinearProgressIndicator(
        value: value,
        minHeight: 4,
        backgroundColor: AuroraColors.butter,
        valueColor: AlwaysStoppedAnimation<Color>(_barColor()),
      ),
    );
  }
}

// ── Budget row ────────────────────────────────────────────────────────────────

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.project, required this.completionPct});

  final Project project;
  final double completionPct;

  @override
  Widget build(BuildContext context) {
    final estimated = project.estimatedBudget;
    final spent = project.actualSpent;

    String leftLabel;
    String rightLabel;

    if (estimated == null) {
      return const SizedBox.shrink();
    }

    switch (project.status) {
      case 'in_progress' || 'on_hold':
        leftLabel = '${(completionPct * 100).round()}% complete';
        rightLabel = '${_compactBudget(spent)} / ${_compactBudget(estimated)}';
      case 'planning':
        leftLabel = 'Estimate';
        rightLabel = '${_compactBudget(estimated)} budget';
      case 'completed':
        final diff = estimated - spent;
        leftLabel = diff > 0
            ? 'Under budget'
            : diff < 0
                ? 'Over budget'
                : 'On budget';
        rightLabel = '${_compactBudget(spent)} / ${_compactBudget(estimated)}';
      default:
        leftLabel = 'Budget';
        rightLabel = _compactBudget(estimated);
    }

    return Row(
      children: [
        Text(
          leftLabel,
          style: AuroraType.labelSm.copyWith(
            color: const Color(0xFF9D9BB0),
          ),
        ),
        const Spacer(),
        Text(
          rightLabel,
          style: AuroraType.labelSm.copyWith(
            color: AuroraColors.inkSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── FAB button ────────────────────────────────────────────────────────────────

class _FabButton extends StatelessWidget {
  const _FabButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AuroraColors.coral,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AuroraColors.coral.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: AuroraColors.paper, size: 26),
      ),
    );
  }
}

// ── No results ────────────────────────────────────────────────────────────────

class _NoResultsState extends StatelessWidget {
  const _NoResultsState({required this.filter, required this.onClear});

  final String? filter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EmptyState(
        icon: CupertinoIcons.search,
        title: 'No results found',
        subtitle: 'Try a different filter.',
        actionLabel: 'Clear filter',
        onAction: onClear,
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
        padding: const EdgeInsets.all(AuroraSpacing.screenPadH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AuroraColors.coral),
            const SizedBox(height: AuroraSpacing.space7),
            Text(
              "Couldn't load projects",
              style: AuroraType.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuroraSpacing.space9),
            PrimaryButton(label: 'Retry', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _ProjectsScreenSkeleton extends StatefulWidget {
  const _ProjectsScreenSkeleton();

  @override
  State<_ProjectsScreenSkeleton> createState() =>
      _ProjectsScreenSkeletonState();
}

class _ProjectsScreenSkeletonState extends State<_ProjectsScreenSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = Tween<double>(begin: 0.3, end: 0.7).animate(_ctrl);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, _) => Opacity(
        opacity: _opacity.value,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBar(width: 130, height: 10, radius: 4),
                  const SizedBox(height: AuroraSpacing.space3),
                  Row(
                    children: [
                      _ShimmerBar(width: 180, height: 26, radius: 6),
                      const Spacer(),
                      _ShimmerBar(width: 60, height: 22, radius: 6),
                    ],
                  ),
                  const SizedBox(height: AuroraSpacing.space2),
                  _ShimmerBar(width: 220, height: 12, radius: 4),
                ],
              ),
            ),
            // Filter chips
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  for (final w in [56.0, 96.0, 80.0, 72.0]) ...[
                    _ShimmerBar(width: w, height: 32, radius: 16),
                    const SizedBox(width: AuroraSpacing.space3),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AuroraSpacing.space7),
            // Section eyebrow
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: _ShimmerBar(width: 100, height: 10, radius: 4),
            ),
            // Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: List.generate(
                  3,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      height: 94,
                      decoration: BoxDecoration(
                        color: AuroraColors.butter,
                        borderRadius: AuroraRadius.md,
                      ),
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

class _ShimmerBar extends StatelessWidget {
  const _ShimmerBar({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AuroraColors.butter,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
