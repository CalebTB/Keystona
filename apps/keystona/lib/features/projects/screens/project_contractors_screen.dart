import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/placeholder_screen.dart';
import '../models/project.dart';
import '../models/project_contractor.dart';
import '../providers/project_contractors_provider.dart';
import '../providers/project_detail_provider.dart';
import '../widgets/contractor_form_sheet.dart';
import '../widgets/contractor_skeleton.dart';
import '../widgets/contractors/ledger/contractors_ledger_view.dart';
import '../widgets/contractors/ledger/contractors_ledger_skeleton.dart';

/// Wrapper screen for the contractors sub-page.
///
/// Loads the project + contractor list, then routes to:
///   - [ContractorsLedgerView]  — active/on-hold projects with data
///   - [PlaceholderScreen]      — story view (deferred spec)
///   - [_EmptyState]            — no contractors yet
///
/// Mirrors the pattern established by [ProjectBudgetScreen].
class ProjectContractorsScreen extends ConsumerStatefulWidget {
  const ProjectContractorsScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<ProjectContractorsScreen> createState() =>
      _ProjectContractorsScreenState();
}

class _ProjectContractorsScreenState
    extends ConsumerState<ProjectContractorsScreen> {
  /// 'ledger' | 'story'. Only relevant when project is active and ≥ 2 vendors.
  String _selectedView = 'ledger';

  void _onAdd() => showContractorFormSheet(
        context: context,
        projectId: widget.projectId,
        ref: ref,
      );

  @override
  Widget build(BuildContext context) {
    final asyncProject =
        ref.watch(projectDetailProvider(widget.projectId));
    final asyncContractors =
        ref.watch(projectContractorsProvider(widget.projectId));
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    // Determine view toggle visibility:
    // Show only when project is NOT completed/cancelled AND contractors >= 2.
    final projectStatus = asyncProject.value?.status;
    final contractorCount = asyncContractors.value?.length ?? 0;
    final isTerminal =
        projectStatus == 'completed' || projectStatus == 'cancelled';
    final showToggle = !isTerminal && contractorCount >= 2;

    final body = asyncProject.when(
      loading: () => const ContractorsLedgerSkeleton(),
      error: (_, _) => _ErrorState(
        onRetry: () {
          ref.invalidate(projectDetailProvider(widget.projectId));
          ref.invalidate(projectContractorsProvider(widget.projectId));
        },
      ),
      data: (project) => asyncContractors.when(
        loading: () => const ContractorSkeleton(),
        error: (_, _) => _ErrorState(
          onRetry: () =>
              ref.invalidate(projectContractorsProvider(widget.projectId)),
        ),
        data: (contractors) => _selectView(project, contractors),
      ),
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Contractors'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _onAdd,
            child: const Icon(CupertinoIcons.add),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (showToggle) _ViewToggle(
                selected: _selectedView,
                onChanged: (v) => setState(() => _selectedView = v),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Contractors')),
      body: Column(
        children: [
          if (showToggle) _ViewToggle(
            selected: _selectedView,
            onChanged: (v) => setState(() => _selectedView = v),
          ),
          Expanded(child: body),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAdd,
        backgroundColor: AppColors.deepNavy,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _selectView(Project project, List<ProjectContractor> contractors) {
    if (contractors.isEmpty) {
      return _EmptyState(onAdd: _onAdd);
    }

    final isTerminal =
        project.status == 'completed' || project.status == 'cancelled';

    if (isTerminal) {
      // Story placeholder — spec deferred.
      return const PlaceholderScreen(name: 'Contractor Story');
    }

    if (_selectedView == 'story') {
      return const PlaceholderScreen(name: 'Contractor Story');
    }

    return ContractorsLedgerView(
      projectId: widget.projectId,
      project: project,
    );
  }
}

// ── View toggle pill ──────────────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      child: Container(
        height: 36,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToggleSegment(
              label: 'Ledger',
              selected: selected == 'ledger',
              onTap: () => onChanged('ledger'),
            ),
            _ToggleSegment(
              label: 'Story',
              selected: selected == 'story',
              onTap: () => onChanged('story'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppPadding.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: AppSizes.iconXl,
              color: AppColors.gray400,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'No contractors yet',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Add the people working on this project — your existing emergency contacts can be added with one tap.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.xl),
            FilledButton(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.deepNavy,
                padding: AppPadding.button,
              ),
              child: const Text('+ Add Contractor'),
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
            Text(
              "Couldn't load contractors",
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.lg),
            FilledButton(
              onPressed: onRetry,
              style:
                  FilledButton.styleFrom(backgroundColor: AppColors.deepNavy),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
