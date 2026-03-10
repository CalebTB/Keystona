import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../../../services/supabase_service.dart';
import '../models/project_journal_note.dart';
import '../providers/project_journal_provider.dart';
import '../widgets/journal_note_card.dart';
import '../widgets/journal_skeleton.dart';

/// Journal feed screen for a single project.
///
/// Shows notes sorted newest-first with swipe-to-delete.
/// Route: /projects/:projectId/notes
class ProjectJournalScreen extends ConsumerStatefulWidget {
  const ProjectJournalScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<ProjectJournalScreen> createState() =>
      _ProjectJournalScreenState();
}

class _ProjectJournalScreenState
    extends ConsumerState<ProjectJournalScreen> {
  final Map<String, String> _phaseNames = {};

  @override
  void initState() {
    super.initState();
    _loadPhaseNames();
  }

  Future<void> _loadPhaseNames() async {
    try {
      final rows = await SupabaseService.client
          .from('project_phases')
          .select('id, name')
          .eq('project_id', widget.projectId);
      if (!mounted) return;
      final names = <String, String>{};
      for (final row in rows as List<dynamic>) {
        final m = row as Map<String, dynamic>;
        names[m['id'] as String] = m['name'] as String;
      }
      setState(() => _phaseNames.addAll(names));
    } catch (_) {
      // Phase names are supplemental — silently ignore failures.
    }
  }

  void _onAddTap() =>
      context.push('/projects/${widget.projectId}/notes/create');

  Future<void> _onDeleteNote(ProjectJournalNote note) async {
    final confirmed = await _confirmDelete(context);
    if (!confirmed) return;

    final notifier =
        ref.read(projectJournalProvider(widget.projectId).notifier);
    try {
      await notifier.deleteNote(note.id);
      if (!mounted) return;
      SnackbarService.showSuccess(context, 'Note deleted.');
    } catch (_) {
      if (!mounted) return;
      SnackbarService.showError(
          context, 'Could not delete note. Please try again.');
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIOS) {
      bool result = false;
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Delete Note'),
          content: const Text('This note will be permanently deleted.'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                result = true;
                Navigator.of(ctx).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      return result;
    } else {
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Note'),
          content: const Text('This note will be permanently deleted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
      return result ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final asyncData = ref.watch(projectJournalProvider(widget.projectId));

    final body = asyncData.when(
      loading: () => const JournalSkeleton(),
      error: (_, _) => _ErrorState(
        onRetry: () => ref.invalidate(projectJournalProvider(widget.projectId)),
      ),
      data: (notes) => notes.isEmpty
          ? _EmptyState(onAddTap: _onAddTap)
          : _NoteList(
              notes: notes,
              phaseNames: _phaseNames,
              projectId: widget.projectId,
              onDelete: _onDeleteNote,
              ref: ref,
            ),
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Journal'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _onAddTap,
            child: const Icon(CupertinoIcons.add),
          ),
        ),
        child: SafeArea(bottom: false, child: body),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Journal')),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddTap,
        backgroundColor: AppColors.deepNavy,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ── Note list ─────────────────────────────────────────────────────────────────

class _NoteList extends StatelessWidget {
  const _NoteList({
    required this.notes,
    required this.phaseNames,
    required this.projectId,
    required this.onDelete,
    required this.ref,
  });

  final List<ProjectJournalNote> notes;
  final Map<String, String> phaseNames;
  final String projectId;
  final void Function(ProjectJournalNote) onDelete;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () =>
              ref.read(projectJournalProvider(projectId).notifier).refresh(),
        ),
        SliverPadding(
          padding: AppPadding.screen.copyWith(top: AppSizes.sm),
          sliver: SliverList.separated(
            itemCount: notes.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
            itemBuilder: (ctx, i) {
              final note = notes[i];
              return Dismissible(
                key: ValueKey(note.id),
                direction: DismissDirection.endToStart,
                background: _DeleteBackground(),
                confirmDismiss: (_) async {
                  onDelete(note);
                  return false;
                },
                child: JournalNoteCard(
                  note: note,
                  phaseName:
                      note.phaseId != null ? phaseNames[note.phaseId] : null,
                  onTap: () => ctx.push(
                    '/projects/$projectId/notes/${note.id}/edit',
                    extra: note,
                  ),
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
              Icons.menu_book_outlined,
              size: AppSizes.iconXl,
              color: AppColors.gray400,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'Start your project journal',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Jot down contractor quotes, material choices, or decisions as you go.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.xl),
            FilledButton(
              onPressed: onAddTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.goldAccent,
                foregroundColor: Colors.white,
                padding: AppPadding.button,
              ),
              child: const Text('+ Add Note'),
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
            Icon(
              Icons.error_outline,
              size: AppSizes.iconXl,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              "Couldn't load journal",
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.lg),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.deepNavy),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
