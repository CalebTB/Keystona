import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/project.dart';
import '../providers/project_detail_provider.dart';
import '../providers/project_phases_provider.dart';

/// Project hub screen — shows project metadata and navigation tiles
/// for each feature sub-section (phases, budget, photos, notes, etc.).
///
/// Route: /projects/:projectId
class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProject = ref.watch(projectDetailProvider(projectId));
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return asyncProject.when(
      loading: () => _skeleton(isIOS),
      error: (_, _) => _errorScaffold(context, ref, isIOS),
      data: (project) => _buildScaffold(context, ref, project, isIOS),
    );
  }

  // ── Loading skeleton ──────────────────────────────────────────────────────

  Widget _skeleton(bool isIOS) {
    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Project'),
        ),
        child: const _DetailSkeleton(),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Project')),
      body: const _DetailSkeleton(),
    );
  }

  // ── Error scaffold ────────────────────────────────────────────────────────

  Widget _errorScaffold(BuildContext context, WidgetRef ref, bool isIOS) {
    final body = Center(
      child: Padding(
        padding: AppPadding.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: AppSizes.iconXl, color: AppColors.error),
            const SizedBox(height: AppSizes.md),
            Text("Couldn't load project",
                style: AppTextStyles.h3, textAlign: TextAlign.center),
            const SizedBox(height: AppSizes.lg),
            FilledButton(
              onPressed: () =>
                  ref.invalidate(projectDetailProvider(projectId)),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.deepNavy),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.back),
            onPressed: () => context.pop(),
          ),
          middle: const Text('Project'),
        ),
        child: body,
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: body,
    );
  }

  // ── Main scaffold ─────────────────────────────────────────────────────────

  Widget _buildScaffold(
    BuildContext context,
    WidgetRef ref,
    Project project,
    bool isIOS,
  ) {
    void onEdit() => context.push(
          '/projects/$projectId/edit',
          extra: project,
        );

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.back),
            onPressed: () => context.pop(),
          ),
          middle: Text(
            project.name,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onEdit,
            child: const Icon(CupertinoIcons.ellipsis),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: _DetailBody(
            project: project,
            projectId: projectId,
            ref: ref,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          project.name,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: onEdit,
          ),
        ],
      ),
      body: _DetailBody(
        project: project,
        projectId: projectId,
        ref: ref,
      ),
    );
  }
}

// ── Detail body ───────────────────────────────────────────────────────────────

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.project,
    required this.projectId,
    required this.ref,
  });

  final Project project;
  final String projectId;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phasesAsync = ref.watch(projectPhasesProvider(projectId));
    final phaseCount = phasesAsync.value?.length ?? project.phaseCount;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(projectDetailProvider(projectId));
        ref.invalidate(projectPhasesProvider(projectId));
      },
      child: CustomScrollView(
        slivers: [
          // ── Project header ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ProjectHeader(project: project),
          ),

          // ── Section tiles ────────────────────────────────────────────
          SliverPadding(
            padding: AppPadding.screen,
            sliver: SliverList.list(
              children: [
                _SectionTile(
                  icon: Icons.format_list_numbered_outlined,
                  label: 'Phases',
                  subtitle: phaseCount == 0
                      ? 'No phases yet'
                      : '$phaseCount phase${phaseCount == 1 ? '' : 's'}',
                  onTap: () => context.push('/projects/$projectId/phases'),
                ),
                const SizedBox(height: AppSizes.sm),
                _SectionTile(
                  icon: Icons.attach_money_outlined,
                  label: 'Budget',
                  subtitle: project.estimatedBudget != null
                      ? '\$${project.actualSpent.toStringAsFixed(0)} of '
                          '\$${project.estimatedBudget!.toStringAsFixed(0)}'
                      : 'No budget set',
                  onTap: () => context.push('/projects/$projectId/budget'),
                ),
                const SizedBox(height: AppSizes.sm),
                _SectionTile(
                  icon: Icons.photo_library_outlined,
                  label: 'Photos',
                  subtitle: 'Before & after, progress',
                  onTap: () => context.push('/projects/$projectId/photos'),
                ),
                const SizedBox(height: AppSizes.sm),
                _SectionTile(
                  icon: Icons.menu_book_outlined,
                  label: 'Journal',
                  subtitle: 'Notes and decisions',
                  onTap: () => context.push('/projects/$projectId/notes'),
                ),
                const SizedBox(height: AppSizes.sm),
                _SectionTile(
                  icon: Icons.people_outline,
                  label: 'Contractors',
                  subtitle: project.contractorIds.isEmpty
                      ? 'No contractors linked'
                      : '${project.contractorIds.length} linked',
                  onTap: () =>
                      context.push('/projects/$projectId/contractors'),
                ),
                const SizedBox(height: AppSizes.sm),
                _SectionTile(
                  icon: Icons.folder_outlined,
                  label: 'Documents',
                  subtitle: 'Permits, quotes, warranties',
                  onTap: () =>
                      context.push('/projects/$projectId/documents'),
                ),
                const SizedBox(height: AppSizes.xl),

                // ── Phase template prompt ────────────────────────────
                if (phaseCount == 0)
                  _TemplatePrompt(
                    project: project,
                    projectId: projectId,
                    ref: ref,
                  ),
              ],
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSizes.xxl),
          ),
        ],
      ),
    );
  }
}

// ── Project header ────────────────────────────────────────────────────────────

class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({required this.project});
  final Project project;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppPadding.screen,
      color: AppColors.deepNavy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusChip(status: project.status),
              const SizedBox(width: AppSizes.sm),
              _WorkTypeChip(workType: project.workType),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            project.projectType.projectTypeLabel,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textInverse.withValues(alpha: 0.7),
            ),
          ),
          if (project.description != null &&
              project.description!.isNotEmpty) ...[
            const SizedBox(height: AppSizes.xs),
            Text(
              project.description!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textInverse.withValues(alpha: 0.85),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        status.statusLabel,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textInverse,
        ),
      ),
    );
  }
}

class _WorkTypeChip extends StatelessWidget {
  const _WorkTypeChip({required this.workType});
  final String workType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.goldAccent.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        workType.workTypeLabel,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.goldAccent,
        ),
      ),
    );
  }
}

// ── Section tile ──────────────────────────────────────────────────────────────

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.cardMinHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.deepNavy, size: 22),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.bodyMediumSemibold),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.gray400, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Phase template prompt ─────────────────────────────────────────────────────

/// Shown when a project has no phases yet — offers to load starter templates.
class _TemplatePrompt extends ConsumerStatefulWidget {
  const _TemplatePrompt({
    required this.project,
    required this.projectId,
    required this.ref,
  });

  final Project project;
  final String projectId;
  final WidgetRef ref;

  @override
  ConsumerState<_TemplatePrompt> createState() => _TemplatePromptState();
}

class _TemplatePromptState extends ConsumerState<_TemplatePrompt> {
  bool _loading = false;

  Future<void> _loadTemplates() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(projectPhasesProvider(widget.projectId).notifier)
          .loadTemplatesAndCreate(widget.project.projectType);
      if (!mounted) return;
      SnackbarService.showSuccess(context, 'Starter phases added!');
    } catch (_) {
      if (!mounted) return;
      SnackbarService.showError(
          context, 'Could not load templates. Add phases manually.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.deepNavy.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: AppColors.deepNavy.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start with a template',
            style: AppTextStyles.bodyMediumSemibold,
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Load starter phases for a '
            '${widget.project.projectType.projectTypeLabel} project.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading ? null : _loadTemplates,
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Load Template'),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              TextButton(
                onPressed: () =>
                    context.push('/projects/${widget.projectId}/phases/create'),
                child: const Text('Add Manually'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Detail skeleton ───────────────────────────────────────────────────────────

class _DetailSkeleton extends StatefulWidget {
  const _DetailSkeleton();

  @override
  State<_DetailSkeleton> createState() => _DetailSkeletonState();
}

class _DetailSkeletonState extends State<_DetailSkeleton>
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
          children: [
            // Header placeholder.
            Container(
              height: 88,
              color: AppColors.deepNavy.withValues(alpha: 0.3),
            ),
            Expanded(
              child: ListView(
                padding: AppPadding.screen,
                children: List.generate(
                  6,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.sm),
                    child: Container(
                      height: AppSizes.cardMinHeight.toDouble(),
                      decoration: BoxDecoration(
                        color: AppColors.gray200,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMd),
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
