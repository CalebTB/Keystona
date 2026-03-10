import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/project_contractor.dart';
import '../providers/project_contractors_provider.dart';
import '../widgets/contractor_card.dart';
import '../widgets/contractor_form_sheet.dart';
import '../widgets/contractor_skeleton.dart';

/// Contractor list for a single project.
///
/// Shows contacts linked to this project with project-specific fields.
/// Route: /projects/:projectId/contractors
class ProjectContractorsScreen extends ConsumerWidget {
  const ProjectContractorsScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncContractors =
        ref.watch(projectContractorsProvider(projectId));
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    void onAdd() => showContractorFormSheet(
          context: context,
          projectId: projectId,
          ref: ref,
        );

    final body = asyncContractors.when(
      loading: () => const ContractorSkeleton(),
      error: (_, _) => _ErrorState(
        onRetry: () => ref
            .invalidate(projectContractorsProvider(projectId)),
      ),
      data: (contractors) => contractors.isEmpty
          ? _EmptyState(onAdd: onAdd)
          : _ContractorList(
              contractors: contractors,
              projectId: projectId,
            ),
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Contractors'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onAdd,
            child: const Icon(CupertinoIcons.add),
          ),
        ),
        child: SafeArea(bottom: false, child: body),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Contractors')),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: onAdd,
        backgroundColor: AppColors.deepNavy,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ── Contractor list ───────────────────────────────────────────────────────────

class _ContractorList extends ConsumerWidget {
  const _ContractorList({
    required this.contractors,
    required this.projectId,
  });

  final List<ProjectContractor> contractors;
  final String projectId;

  Future<void> _remove(
      BuildContext context, WidgetRef ref, ProjectContractor c) async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    bool confirmed = false;

    if (isIOS) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Remove Contractor'),
          content: Text(
              'Remove ${c.contactName} from this project? The contact will stay in your contacts list.'),
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
              child: const Text('Remove'),
            ),
          ],
        ),
      );
    } else {
      confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Remove Contractor'),
              content: Text(
                  'Remove ${c.contactName} from this project?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text('Remove',
                      style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          ) ??
          false;
    }

    if (!confirmed || !context.mounted) return;

    final notifier = ref.read(
        projectContractorsProvider(projectId).notifier);
    try {
      await notifier.removeContractor(c.id);
      if (!context.mounted) return;
      SnackbarService.showSuccess(context, 'Contractor removed.');
    } catch (_) {
      if (!context.mounted) return;
      SnackbarService.showError(context, 'Could not remove contractor.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async => ref
          .read(projectContractorsProvider(projectId).notifier)
          .refresh(),
      child: ListView.separated(
        padding: AppPadding.screen,
        itemCount: contractors.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
        itemBuilder: (ctx, i) {
          final c = contractors[i];
          return Dismissible(
            key: ValueKey(c.id),
            direction: DismissDirection.endToStart,
            background: _DeleteBackground(),
            confirmDismiss: (_) async {
              await _remove(ctx, ref, c);
              return false;
            },
            child: ContractorCard(
              contractor: c,
              onTap: () => showContractorFormSheet(
                context: ctx,
                projectId: projectId,
                ref: ref,
                existingContractor: c,
              ),
            ),
          );
        },
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
      child: const Icon(Icons.person_remove_outlined, color: Colors.white),
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
              'Add your project team',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Link contractors, designers, and other professionals working on this project.',
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
            Text("Couldn't load contractors",
                style: AppTextStyles.h3, textAlign: TextAlign.center),
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
