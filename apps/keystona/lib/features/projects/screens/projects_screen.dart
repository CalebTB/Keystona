import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/project.dart';
import '../providers/projects_provider.dart';
import '../widgets/project_card.dart';
import '../widgets/project_empty_state.dart';
import '../widgets/project_list_skeleton.dart';

/// Projects list screen — Tab 3.
///
/// Shows all non-deleted projects for the current property, with
/// status filter chips and a FAB to create a new project.
/// The free-tier limit (2 projects) gates creation via [_checkFreeTierLimit].
class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  /// null = show all statuses.
  String? _activeFilter;

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final asyncData = ref.watch(projectsProvider);

    return asyncData.when(
      loading: () => _scaffold(
        isIOS: isIOS,
        body: const ProjectListSkeleton(),
        projectCount: 0,
      ),
      error: (e, _) => _scaffold(
        isIOS: isIOS,
        body: _ErrorState(
          onRetry: () => ref.invalidate(projectsProvider),
        ),
        projectCount: 0,
      ),
      data: (projects) {
        final filtered = _activeFilter == null
            ? projects
            : projects
                .where((p) => p.status == _activeFilter)
                .toList();

        return _scaffold(
          isIOS: isIOS,
          body: projects.isEmpty
              ? ProjectEmptyState(onCreateProject: _onCreateTap)
              : _ProjectList(
                  projects: filtered,
                  allProjects: projects,
                  activeFilter: _activeFilter,
                  onFilterChanged: (f) => setState(() => _activeFilter = f),
                  ref: ref,
                ),
          projectCount: projects.length,
        );
      },
    );
  }

  Widget _scaffold({
    required bool isIOS,
    required Widget body,
    required int projectCount,
  }) {
    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Projects'),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              body,
              if (projectCount > 0)
                Positioned(
                  bottom: AppSizes.lg,
                  right: AppSizes.md,
                  child: _FAB(
                    onTap: _onCreateTap,
                    projectCount: projectCount,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: _onCreateTap,
        backgroundColor: AppColors.deepNavy,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _onCreateTap() {
    context.push(AppRoutes.projectsCreate);
  }
}

// ── Project list with filter chips ───────────────────────────────────────────

class _ProjectList extends StatelessWidget {
  const _ProjectList({
    required this.projects,
    required this.allProjects,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.ref,
  });

  final List<Project> projects;
  final List<Project> allProjects;
  final String? activeFilter;
  final ValueChanged<String?> onFilterChanged;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () => ref.read(projectsProvider.notifier).refresh(),
        ),

        // ── Filter chips ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _FilterChips(
            activeFilter: activeFilter,
            onChanged: onFilterChanged,
          ),
        ),

        // ── Project cards ─────────────────────────────────────────────
        SliverPadding(
          padding: AppPadding.screen.copyWith(top: AppSizes.sm),
          sliver: projects.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: _NoResultsState(
                    filter: activeFilter,
                    onClear: () => onFilterChanged(null),
                  ),
                )
              : SliverList.separated(
                  itemCount: projects.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSizes.sm),
                  itemBuilder: (ctx, i) => ProjectCard(
                    project: projects[i],
                    onTap: () => ctx.push(
                      AppRoutes.projectDetail.replaceFirst(
                        ':projectId',
                        projects[i].id,
                      ),
                    ),
                  ),
                ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: AppSizes.xxl + AppSizes.xl),
        ),
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
                backgroundColor: AppColors.deepNavy,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
