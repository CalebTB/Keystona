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
  final ValueNotifier<int> _currentPage = ValueNotifier(0);

  @override
  void dispose() {
    _pageController.dispose();
    _currentPage.dispose();
    super.dispose();
  }

  void _onFilterChanged(String? filter) {
    setState(() {
      _activeFilter = filter;
    });
    _currentPage.value = 0;
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final asyncData = ref.watch(projectsProvider);

    final body = asyncData.when(
      loading: () => const _ProjectsScreenSkeleton(),
      error: (_, _) => _ErrorState(onRetry: () => ref.invalidate(projectsProvider)),
      data: (projects) {
        if (projects.isEmpty) {
          return ProjectEmptyState(onCreateProject: _onCreateTap);
        }

        final filtered = _activeFilter == null
            ? projects
            : projects.where((p) => p.status == _activeFilter).toList();


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
            const SizedBox(height: 16),
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
                      onPageChanged: (i) => _currentPage.value = i,
                      itemBuilder: (ctx, i) => RepaintBoundary(
                        child: ProjectPhaseTimelineCard(
                          project: filtered[i],
                          onOpen: () => context.push(
                            AppRoutes.projectDetail.replaceFirst(':projectId', filtered[i].id),
                          ),
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
                  child: ValueListenableBuilder<int>(
                    valueListenable: _currentPage,
                    builder: (_, current, _) => _PageDots(
                      total: filtered.length,
                      current: current.clamp(0, filtered.length - 1),
                    ),
                  ),
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
    final dotSize = total > 8 ? 5.0 : 6.0;
    final spacing = total > 8 ? 2.0 : 3.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Wrap(
            alignment: WrapAlignment.center,
            children: List.generate(total, (i) {
          final active = i == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: active ? 14 : dotSize,
            height: dotSize,
            margin: EdgeInsets.symmetric(horizontal: spacing),
            decoration: BoxDecoration(
              color: active ? AppColors.deepNavy : Colors.transparent,
              borderRadius: BorderRadius.circular(dotSize),
              border: active
                  ? null
                  : Border.all(color: AppColors.deepNavy.withValues(alpha: 0.25), width: 1),
            ),
          );
        }),
          ),
        ),
      ],
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

// ── Projects screen skeleton ───────────────────────────────────────────────────

class _ProjectsScreenSkeleton extends StatefulWidget {
  const _ProjectsScreenSkeleton();

  @override
  State<_ProjectsScreenSkeleton> createState() => _ProjectsScreenSkeletonState();
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
            // ── Header shimmer ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBar(width: 70, height: 10, radius: 4),
                      const SizedBox(height: 6),
                      _ShimmerBar(width: 180, height: 22, radius: 6),
                    ],
                  ),
                  const Spacer(),
                  _ShimmerBar(width: 40, height: 40, radius: 20),
                ],
              ),
            ),
            // ── Filter chips shimmer ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  for (final w in [56.0, 88.0, 72.0, 80.0]) ...[
                    _ShimmerBar(width: w, height: 32, radius: 16),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── Card shimmer ─────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Dark header section
                    Container(
                      width: double.infinity,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: Color(0xFF352C24),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ShimmerBar(width: 100, height: 10, radius: 4, dark: true),
                          const SizedBox(height: 10),
                          _ShimmerBar(width: 220, height: 22, radius: 6, dark: true),
                          const SizedBox(height: 12),
                          Row(children: [
                            _ShimmerBar(width: 60, height: 10, radius: 4, dark: true),
                            const SizedBox(width: 12),
                            _ShimmerBar(width: 60, height: 10, radius: 4, dark: true),
                            const SizedBox(width: 12),
                            _ShimmerBar(width: 80, height: 10, radius: 4, dark: true),
                          ]),
                        ],
                      ),
                    ),
                    // White timeline section
                    Expanded(
                      child: Container(
                        color: AppColors.surface,
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                        child: Column(
                          children: List.generate(4, (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _ShimmerBar(width: 22, height: 22, radius: 11),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _ShimmerBar(width: 140 + (i * 20).toDouble(), height: 14, radius: 4),
                                    const SizedBox(height: 5),
                                    _ShimmerBar(width: 200, height: 10, radius: 4),
                                  ],
                                ),
                              ],
                            ),
                          )),
                        ),
                      ),
                    ),
                    // Footer section
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: AppColors.warmFill,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 14, 16, 16),
                      child: Row(
                        children: [
                          _ShimmerBar(width: 80, height: 20, radius: 5),
                          const SizedBox(width: 10),
                          _ShimmerBar(width: 100, height: 10, radius: 4),
                          const Spacer(),
                          _ShimmerBar(width: 60, height: 30, radius: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Dots shimmer ─────────────────────────────────────────────────
            ColoredBox(
              color: AppColors.warmOffWhite,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ShimmerBar(width: 14, height: 6, radius: 3),
                    const SizedBox(width: 6),
                    _ShimmerBar(width: 6, height: 6, radius: 3),
                    const SizedBox(width: 6),
                    _ShimmerBar(width: 6, height: 6, radius: 3),
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

class _ShimmerBar extends StatelessWidget {
  const _ShimmerBar({
    required this.width,
    required this.height,
    required this.radius,
    this.dark = false,
  });

  final double width;
  final double height;
  final double radius;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.15)
            : AppColors.gray200,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
