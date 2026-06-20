import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
  String? _selectedPhaseId;

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

  Map<String, String> _linkedPhases(List<ProjectJournalNote> notes) {
    final ids = notes
        .where((n) => n.phaseId != null)
        .map((n) => n.phaseId!)
        .toSet();
    return {
      for (final id in ids)
        if (_phaseNames.containsKey(id)) id: _phaseNames[id]!,
    };
  }

  Future<void> _showFilterSheet(
    BuildContext ctx,
    Map<String, String> linked,
  ) async {
    const kClear = '__all__';
    String? picked;

    await showCupertinoModalPopup<void>(
      context: ctx,
      builder: (sheetCtx) => CupertinoActionSheet(
        title: const Text('Filter by Phase'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              picked = kClear;
              Navigator.of(sheetCtx).pop();
            },
            child: Row(
              children: [
                const Expanded(child: Text('All notes')),
                if (_selectedPhaseId == null)
                  const Icon(CupertinoIcons.checkmark, size: 16),
              ],
            ),
          ),
          ...linked.entries.map(
            (e) => CupertinoActionSheetAction(
              onPressed: () {
                picked = e.key;
                Navigator.of(sheetCtx).pop();
              },
              child: Row(
                children: [
                  Expanded(child: Text(e.value)),
                  if (_selectedPhaseId == e.key)
                    const Icon(CupertinoIcons.checkmark, size: 16),
                ],
              ),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(sheetCtx).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );

    if (picked == null || !mounted) return;
    setState(() =>
        _selectedPhaseId = picked == kClear ? null : picked);
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
    final allNotes = asyncData.value ?? [];
    final linked = _linkedPhases(allNotes);
    final isFiltered = _selectedPhaseId != null;

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
              selectedPhaseId: _selectedPhaseId,
            ),
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Journal'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (linked.isNotEmpty)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _showFilterSheet(context, linked),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        CupertinoIcons.slider_horizontal_3,
                        color: isFiltered ? AppColors.accent : null,
                      ),
                      if (isFiltered)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _onAddTap,
                child: const Icon(CupertinoIcons.add),
              ),
            ],
          ),
        ),
        child: SafeArea(bottom: false, child: body),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        actions: [
          if (linked.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.filter_list,
                color: isFiltered ? AppColors.accent : null,
              ),
              onPressed: () => _showFilterSheet(context, linked),
            ),
        ],
      ),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddTap,
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: AppColors.textInverse),
      ),
    );
  }
}

// ── Timeline item types ───────────────────────────────────────────────────────

sealed class _ListItem { const _ListItem(); }

class _HeaderItem extends _ListItem {
  const _HeaderItem(this.label);
  final String label;
}

class _NoteItem extends _ListItem {
  const _NoteItem(this.note);
  final ProjectJournalNote note;
}

// ── Note list ─────────────────────────────────────────────────────────────────

class _NoteList extends ConsumerStatefulWidget {
  const _NoteList({
    required this.notes,
    required this.phaseNames,
    required this.projectId,
    required this.onDelete,
    this.selectedPhaseId,
  });

  final List<ProjectJournalNote> notes;
  final Map<String, String> phaseNames;
  final String projectId;
  final void Function(ProjectJournalNote) onDelete;
  final String? selectedPhaseId;

  @override
  ConsumerState<_NoteList> createState() => _NoteListState();
}

class _NoteListState extends ConsumerState<_NoteList> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';

  static final _monthFmt = DateFormat('MMMM yyyy');

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = val.toLowerCase().trim());
    });
  }

  List<ProjectJournalNote> get _filtered {
    var result = widget.notes;
    if (widget.selectedPhaseId != null) {
      result = result
          .where((n) => n.phaseId == widget.selectedPhaseId)
          .toList();
    }
    if (_query.isNotEmpty) {
      result = result.where((n) =>
          (n.title?.toLowerCase().contains(_query) ?? false) ||
          n.content.toLowerCase().contains(_query)).toList();
    }
    return result;
  }

  List<_ListItem> _buildItems(List<ProjectJournalNote> notes) {
    final items = <_ListItem>[];
    String? currentMonth;
    for (final note in notes) {
      final month = _monthFmt.format(note.noteDate);
      if (month != currentMonth) {
        items.add(_HeaderItem(month));
        currentMonth = month;
      }
      items.add(_NoteItem(note));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final items = _buildItems(filtered);
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () => ref
              .read(projectJournalProvider(widget.projectId).notifier)
              .refresh(),
        ),

        // Search bar
        SliverToBoxAdapter(
          child: Padding(
            padding: AppPadding.screen.copyWith(bottom: 0),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.sm),
              child: isIOS
                  ? CupertinoSearchTextField(
                      controller: _searchCtrl,
                      placeholder: 'Search notes…',
                      onChanged: _onSearchChanged,
                    )
                  : TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search notes…',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md,
                          vertical: AppSizes.sm,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
            ),
          ),
        ),

        // Summary bar (hidden while searching or filtering)
        if (_query.isEmpty && widget.selectedPhaseId == null)
          SliverToBoxAdapter(
            child: Padding(
              padding: AppPadding.screen.copyWith(bottom: 0),
              child: _SummaryBar(notes: widget.notes),
            ),
          ),

        // Notes feed or no-results state
        if (filtered.isEmpty && _query.isNotEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: AppPadding.screen,
                child: Text(
                  'No notes match "$_query"',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: AppPadding.screen.copyWith(top: AppSizes.sm),
            sliver: SliverList.builder(
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i];
                return switch (item) {
                  _HeaderItem(:final label) => Padding(
                      padding: EdgeInsets.only(
                        top: i == 0 ? 0 : AppSizes.md,
                        bottom: AppSizes.sm,
                      ),
                      child: _MonthHeader(label: label),
                    ),
                  _NoteItem(:final note) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.sm),
                      child: Dismissible(
                        key: ValueKey(note.id),
                        direction: DismissDirection.endToStart,
                        background: _DeleteBackground(),
                        confirmDismiss: (_) async {
                          widget.onDelete(note);
                          return false;
                        },
                        child: JournalNoteCard(
                          note: note,
                          phaseName: note.phaseId != null
                              ? widget.phaseNames[note.phaseId]
                              : null,
                          onTap: () => ctx.push(
                            '/projects/${widget.projectId}/notes/${note.id}/edit',
                            extra: note,
                          ),
                        ),
                      ),
                    ),
                };
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

// ── Summary bar ───────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.notes});

  final List<ProjectJournalNote> notes;

  static final _sinceFmt = DateFormat("MMM ''yy");

  @override
  Widget build(BuildContext context) {
    final phaseCount =
        notes.where((n) => n.phaseId != null).map((n) => n.phaseId!).toSet().length;

    // Notes are sorted newest-first; oldest is last.
    final oldest = notes.last.noteDate;
    final sinceLabel = _sinceFmt.format(oldest);

    final parts = [
      '${notes.length} ${notes.length == 1 ? 'note' : 'notes'}',
      if (phaseCount > 0)
        '$phaseCount ${phaseCount == 1 ? 'phase' : 'phases'}',
      'since $sinceLabel',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
                child: Text(
                  '·',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.gray400,
                  ),
                ),
              ),
            Text(
              parts[i],
              style: AppTextStyles.caption.copyWith(
                color: i == 0
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: i == 0 ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Month section header ──────────────────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        const Expanded(
          child: Divider(thickness: 1),
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
      child: const Icon(Icons.delete_outline, color: AppColors.textInverse),
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
                foregroundColor: AppColors.textInverse,
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
                  backgroundColor: AppColors.accent),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
