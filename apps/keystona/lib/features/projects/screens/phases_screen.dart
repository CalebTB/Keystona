import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/project_phase.dart';
import '../providers/project_phases_provider.dart';
import '../widgets/phase_card.dart';
import '../widgets/phase_list_skeleton.dart';

/// Project Phases list screen.
///
/// Shows all phases for a project with reordering via up/down arrows and
/// swipe-to-delete. FAB/nav-bar button opens the phase create form.
///
/// Route: /projects/:projectId/phases
class PhasesScreen extends ConsumerWidget {
  const PhasesScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPhases = ref.watch(projectPhasesProvider(projectId));
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    void onAddTap() =>
        context.push('/projects/$projectId/phases/create');

    final body = asyncPhases.when(
      loading: () => const PhaseListSkeleton(),
      error: (_, _) => _ErrorState(
        onRetry: () => ref.invalidate(projectPhasesProvider(projectId)),
      ),
      data: (phases) => phases.isEmpty
          ? _EmptyState(onAddTap: onAddTap)
          : _PhaseList(
              phases: phases,
              projectId: projectId,
            ),
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Phases'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onAddTap,
            child: const Icon(CupertinoIcons.add),
          ),
        ),
        child: SafeArea(bottom: false, child: body),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Phases')),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: onAddTap,
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ── Phase list with reorder + swipe-delete ────────────────────────────────────

class _PhaseList extends ConsumerWidget {
  const _PhaseList({
    required this.phases,
    required this.projectId,
  });

  final List<ProjectPhase> phases;
  final String projectId;

  Future<void> _reorderPhase(
    BuildContext context,
    WidgetRef ref,
    int oldIndex,
    int newIndex,
  ) async {
    final notifier =
        ref.read(projectPhasesProvider(projectId).notifier);
    final reordered = List<ProjectPhase>.from(phases);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    final ids = reordered.map((p) => p.id).toList();
    try {
      await notifier.reorderPhases(ids);
    } catch (_) {
      if (!context.mounted) return;
      SnackbarService.showError(context, 'Could not reorder phases.');
    }
  }

  Future<void> _showStatusPicker(
    BuildContext context,
    WidgetRef ref,
    ProjectPhase phase,
  ) async {
    final next = PhaseStatusTransitions.nextFor(phase.status);
    if (next.isEmpty) return;

    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    String? picked;

    if (isIOS) {
      await showCupertinoModalPopup<void>(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: Text(phase.name),
          message: const Text('Move to status'),
          actions: next
              .map(
                (s) => CupertinoActionSheetAction(
                  onPressed: () {
                    picked = s;
                    Navigator.of(ctx).pop();
                  },
                  child: Text(s.phaseStatusLabel),
                ),
              )
              .toList(),
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ),
      );
    } else {
      picked = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSizes.md, AppSizes.md, AppSizes.md, AppSizes.xs),
                child: Text('Move to status',
                    style: AppTextStyles.bodyMediumSemibold),
              ),
              ...next.map(
                (s) => ListTile(
                  title: Text(s.phaseStatusLabel),
                  onTap: () => Navigator.of(ctx).pop(s),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (picked == null || !context.mounted) return;

    final notifier = ref.read(projectPhasesProvider(projectId).notifier);
    try {
      await notifier.updatePhase(phase.id, {'status': picked});
    } catch (_) {
      if (!context.mounted) return;
      SnackbarService.showError(context, 'Could not update status.');
    }
  }

  Future<void> _deletePhase(BuildContext context, WidgetRef ref, ProjectPhase phase) async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    bool confirmed = false;

    if (isIOS) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Delete Phase'),
          content: const Text(
              'This phase will be deleted. Budget items and notes keep their project link.'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                confirmed = true;
                Navigator.of(ctx).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    } else {
      confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete Phase'),
              content: const Text(
                  'This phase will be deleted. Budget items and notes keep their project link.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text('Delete',
                      style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          ) ??
          false;
    }

    if (!confirmed || !context.mounted) return;

    final notifier =
        ref.read(projectPhasesProvider(projectId).notifier);
    try {
      await notifier.deletePhase(phase.id);
      if (!context.mounted) return;
      SnackbarService.showSuccess(context, 'Phase deleted.');
    } catch (_) {
      if (!context.mounted) return;
      SnackbarService.showError(
          context, 'Could not delete phase. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () =>
              ref.read(projectPhasesProvider(projectId).notifier).refresh(),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: AppPadding.screen.copyWith(bottom: 0),
            child: _ProgressHeader(phases: phases),
          ),
        ),
        SliverPadding(
          padding: AppPadding.screen.copyWith(top: AppSizes.sm),
          sliver: SliverList.separated(
            itemCount: phases.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
            itemBuilder: (ctx, i) {
              final phase = phases[i];
              return Dismissible(
                key: ValueKey(phase.id),
                direction: DismissDirection.endToStart,
                background: _DeleteBackground(),
                confirmDismiss: (_) async {
                  await _deletePhase(ctx, ref, phase);
                  return false;
                },
                child: PhaseCard(
                  phase: phase,
                  onTap: () => ctx.push(
                    '/projects/$projectId/phases/${phase.id}/edit',
                    extra: phase,
                  ),
                  onStatusTap: () => _showStatusPicker(ctx, ref, phase),
                  onMoveUp: i > 0
                      ? () => _reorderPhase(ctx, ref, i, i - 1)
                      : null,
                  onMoveDown: i < phases.length - 1
                      ? () => _reorderPhase(ctx, ref, i, i + 1)
                      : null,
                ),
              );
            },
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: AppSizes.xxl + AppSizes.xl),
        ),
      ],
    );
  }
}

// ── Progress header ───────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.phases});

  final List<ProjectPhase> phases;

  @override
  Widget build(BuildContext context) {
    final active = phases
        .where((p) => p.status != 'cancelled' && p.deletedAt == null)
        .toList();
    final total = active.length;
    if (total == 0) return const SizedBox.shrink();

    final completed = active.where((p) => p.status == 'completed').length;
    final inProgress = active.where((p) => p.status == 'in_progress').length;
    final fraction = completed / total;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm + 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$completed of $total complete',
                style: AppTextStyles.bodyMediumSemibold,
              ),
              if (inProgress > 0) ...[
                const SizedBox(width: AppSizes.xs),
                Text(
                  '· $inProgress in progress',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.slate,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '${(fraction * 100).round()}%',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: AppColors.warmInset,
              valueColor: AlwaysStoppedAnimation<Color>(
                completed == total ? AppColors.olive : AppColors.slate,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: const Icon(Icons.delete_outline, color: Colors.white),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddTap});
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppPadding.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.playlist_add_outlined,
              size: AppSizes.iconXl,
              color: AppColors.gray400,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'Break your project into phases',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Phases keep your project organized from start to finish.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.xl),
            FilledButton(
              onPressed: onAddTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: AppPadding.button,
              ),
              child: const Text('+ Add Phase'),
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
            Icon(Icons.error_outline,
                size: AppSizes.iconXl, color: AppColors.error),
            const SizedBox(height: AppSizes.md),
            Text("Couldn't load phases",
                style: AppTextStyles.h3, textAlign: TextAlign.center),
            const SizedBox(height: AppSizes.lg),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
