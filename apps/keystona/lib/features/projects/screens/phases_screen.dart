import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/theme/aurora_spacing.dart';

import '../../../core/widgets/snackbar_service.dart';
import '../models/project_phase.dart';
import '../providers/project_phases_provider.dart';
import '../widgets/phase_card.dart';
import '../widgets/phase_list_skeleton.dart';

/// Project Phases list screen.
///
/// Shows all phases for a project with drag-to-reorder and swipe-to-delete.
/// FAB/nav-bar button opens the phase create form.
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
        backgroundColor: AuroraColors.coral,
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

  Future<void> _onReorder(
    BuildContext context,
    WidgetRef ref,
    int oldIndex,
    int newIndex,
  ) async {
    // SliverReorderableList passes newIndex computed before removal;
    // adjust when moving an item down the list.
    if (newIndex > oldIndex) newIndex -= 1;
    final reordered = List<ProjectPhase>.from(phases);
    reordered.insert(newIndex, reordered.removeAt(oldIndex));
    final ids = reordered.map((p) => p.id).toList();
    try {
      await ref.read(projectPhasesProvider(projectId).notifier).reorderPhases(ids);
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
                    AuroraSpacing.space7, AuroraSpacing.space7, AuroraSpacing.space7, AuroraSpacing.space1),
                child: Text('Move to status',
                    style: AuroraType.h3),
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
                      style: TextStyle(color: AuroraColors.coral)),
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
            padding: EdgeInsets.all(AuroraSpacing.screenPadH).copyWith(bottom: 0),
            child: _ProgressHeader(phases: phases),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.all(AuroraSpacing.screenPadH).copyWith(top: AuroraSpacing.space3),
          sliver: SliverReorderableList(
            itemCount: phases.length,
            onReorder: (oldIndex, newIndex) =>
                _onReorder(context, ref, oldIndex, newIndex),
            itemBuilder: (ctx, i) {
              final phase = phases[i];
              return ReorderableDelayedDragStartListener(
                key: ValueKey(phase.id),
                index: i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AuroraSpacing.space3),
                  child: Dismissible(
                    key: Key('dismiss_${phase.id}'),
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
                      leading: Icon(
                        Icons.drag_handle,
                        size: 20,
                        color: AuroraColors.inkTertiary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 48.0 + AuroraSpacing.space10),
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
      margin: const EdgeInsets.only(bottom: AuroraSpacing.space3),
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.space7,
        vertical: AuroraSpacing.space3 + 4,
      ),
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AuroraColors.inkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$completed of $total complete',
                style: AuroraType.h3,
              ),
              if (inProgress > 0) ...[
                const SizedBox(width: AuroraSpacing.space1),
                Text(
                  '· $inProgress in progress',
                  style: AuroraType.body.copyWith(
                    color: AuroraColors.cobalt,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '${(fraction * 100).round()}%',
                style: AuroraType.label.copyWith(
                  color: AuroraColors.inkSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AuroraSpacing.space3),
          ClipRRect(
            borderRadius: BorderRadius.circular(999.0),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: AuroraColors.butter,
              valueColor: AlwaysStoppedAnimation<Color>(
                completed == total ? AuroraColors.lime : AuroraColors.cobalt,
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
      padding: const EdgeInsets.only(right: AuroraSpacing.space9),
      decoration: BoxDecoration(
        color: AuroraColors.coral,
        borderRadius: BorderRadius.circular(12.0),
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
        padding: EdgeInsets.all(AuroraSpacing.screenPadH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.playlist_add_outlined,
              size: 48.0,
              color: AuroraColors.inkTertiary,
            ),
            const SizedBox(height: AuroraSpacing.space7),
            Text(
              'Break your project into phases',
              style: AuroraType.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuroraSpacing.space3),
            Text(
              'Phases keep your project organized from start to finish.',
              style: AuroraType.body
                  .copyWith(color: AuroraColors.inkSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuroraSpacing.space10),
            FilledButton(
              onPressed: onAddTap,
              style: FilledButton.styleFrom(
                backgroundColor: AuroraColors.coral,
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
        padding: EdgeInsets.all(AuroraSpacing.screenPadH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48.0, color: AuroraColors.coral),
            const SizedBox(height: AuroraSpacing.space7),
            Text("Couldn't load phases",
                style: AuroraType.h3, textAlign: TextAlign.center),
            const SizedBox(height: AuroraSpacing.space9),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                  backgroundColor: AuroraColors.coral),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
