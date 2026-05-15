import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/upgrade_sheet.dart';
import '../../../services/providers/service_providers.dart';
import '../../subscription/providers/subscription_provider.dart';
import '../models/project.dart';
import '../providers/projects_provider.dart';
import '../widgets/project_empty_state.dart';
import '../widgets/project_phase_timeline_card.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  String? _activeFilter;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onFilterChanged(String? filter) {
    setState(() {
      _activeFilter = filter;
      _currentPage = 0;
    });
    // Jump to page 0 when filter changes
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final asyncData = ref.watch(projectsProvider);

    final body = asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, _) => _ErrorState(onRetry: () => ref.invalidate(projectsProvider)),
      data: (projects) {
        if (projects.isEmpty) {
          return ProjectEmptyState(onCreateProject: _onCreateTap);
        }

        final filtered = _activeFilter == null
            ? projects
            : projects.where((p) => p.status == _activeFilter).toList();

        final page = _currentPage.clamp(0, (filtered.length - 1).clamp(0, filtered.length));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Eyebrow + heading ───────────────────────────────────────────
            _Header(
              totalCount: projects.length,
              onAdd: _onCreateTap,
            ),
            // ── Filter chips ────────────────────────────────────────────────
            _FilterChips(
              projects: projects,
              activeFilter: _activeFilter,
              onChanged: _onFilterChanged,
            ),
            const SizedBox(height: 8),
            // ── Page view ────────────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _NoResultsState(
                      filter: _activeFilter,
                      onClear: () => _onFilterChanged(null),
                    )
                  : PageView.builder(
                      key: ValueKey(_activeFilter),
                      controller: _pageController,
                      itemCount: filtered.length,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemBuilder: (ctx, i) => ProjectPhaseTimelineCard(
                        project: filtered[i],
                        onOpen: () => context.push(
                          AppRoutes.projectDetail.replaceFirst(':projectId', filtered[i].id),
                        ),
                      ),
                    ),
            ),
            // ── Page dots ───────────────────────────────────────────────────
            if (filtered.isNotEmpty && filtered.length > 1)
              ColoredBox(
                color: AppColors.warmOffWhite,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: _PageDots(total: filtered.length, current: page),
                ),
              ),
          ],
        );
      },
    );

    final scaffold = CupertinoPageScaffold(
      child: SafeArea(
        bottom: false,
        child: body,
      ),
    );

    if (isIOS) return scaffold;

    return Scaffold(
      body: SafeArea(bottom: false, child: body),
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

class _Header extends StatelessWidget {
  const _Header({required this.totalCount, required this.onAdd});

  final int totalCount;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PROJECTS',
                style: AppTextStyles.monoSection.copyWith(
                  fontSize: 10,
                  color: AppColors.accent,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your renovations',
                style: AppTextStyles.headlineMedium.copyWith(fontSize: 26),
              ),
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

// ── Filter chips ──────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.projects,
    required this.activeFilter,
    required this.onChanged,
  });

  final List<Project> projects;
  final String? activeFilter;
  final ValueChanged<String?> onChanged;

  static const _filters = [
    (value: null,          label: 'All'),
    (value: 'in_progress', label: 'In Progress'),
    (value: 'planning',    label: 'Planning'),
    (value: 'on_hold',     label: 'On Hold'),
    (value: 'completed',   label: 'Completed'),
    (value: 'cancelled',   label: 'Cancelled'),
  ];

  int _count(String? status) => status == null
      ? projects.length
      : projects.where((p) => p.status == status).length;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          for (int i = 0; i < _filters.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _Chip(
              label: _filters[i].label,
              count: _count(_filters[i].value),
              selected: activeFilter == _filters[i].value,
              onTap: () => onChanged(
                activeFilter == _filters[i].value && _filters[i].value != null
                    ? null
                    : _filters[i].value,
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.deepNavy : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: selected ? AppColors.deepNavy : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.15)
                    : AppColors.warmFill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.monoSection.copyWith(
                  fontSize: 9,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.8)
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page dots ─────────────────────────────────────────────────────────────────

class _PageDots extends StatelessWidget {
  const _PageDots({required this.total, required this.current});

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: active ? 16 : 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? AppColors.deepNavy : Colors.transparent,
            borderRadius: BorderRadius.circular(3),
            border: active
                ? null
                : Border.all(color: AppColors.deepNavy.withValues(alpha: 0.25), width: 1),
          ),
        );
      }),
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
      child: Padding(
        padding: AppPadding.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list_off, size: AppSizes.iconXl, color: AppColors.gray400),
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
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.deepNavy),
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
            Text("Couldn't load projects", style: AppTextStyles.h3, textAlign: TextAlign.center),
            const SizedBox(height: AppSizes.lg),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
