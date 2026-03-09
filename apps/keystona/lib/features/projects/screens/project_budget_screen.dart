import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/project_budget_item.dart';
import '../providers/project_budget_provider.dart';
import '../widgets/budget_item_card.dart';
import '../widgets/budget_skeleton.dart';

/// Budget overview and line-item list for a single project.
///
/// Route: /projects/:projectId/budget
class ProjectBudgetScreen extends ConsumerWidget {
  const ProjectBudgetScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(projectBudgetProvider(projectId));
    final asyncSummary = ref.watch(projectBudgetSummaryProvider(projectId));
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    void onAdd() => context.push('/projects/$projectId/budget/create');

    final body = asyncItems.when(
      loading: () => const BudgetSkeleton(),
      error: (_, _) => _ErrorState(
        onRetry: () =>
            ref.invalidate(projectBudgetProvider(projectId)),
      ),
      data: (items) => _BudgetBody(
        items: items,
        asyncSummary: asyncSummary,
        projectId: projectId,
        ref: ref,
      ),
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Budget'),
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
      appBar: AppBar(title: const Text('Budget')),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: onAdd,
        backgroundColor: AppColors.deepNavy,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ── Budget body ───────────────────────────────────────────────────────────────

class _BudgetBody extends ConsumerWidget {
  const _BudgetBody({
    required this.items,
    required this.asyncSummary,
    required this.projectId,
    required this.ref,
  });

  final List<ProjectBudgetItem> items;
  final AsyncValue<BudgetSummary> asyncSummary;
  final String projectId;
  final WidgetRef ref;

  Future<void> _deleteItem(
    BuildContext context,
    WidgetRef ref,
    ProjectBudgetItem item,
  ) async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    bool confirmed = false;

    if (isIOS) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Delete Item'),
          content: const Text('This budget item will be permanently deleted.'),
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
              title: const Text('Delete Item'),
              content:
                  const Text('This budget item will be permanently deleted.'),
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
        ref.read(projectBudgetProvider(projectId).notifier);
    try {
      await notifier.deleteItem(item.id);
      if (!context.mounted) return;
      SnackbarService.showSuccess(context, 'Item deleted.');
    } catch (_) {
      if (!context.mounted) return;
      SnackbarService.showError(
          context, 'Could not delete item. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = asyncSummary.value;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(projectBudgetProvider(projectId));
        ref.invalidate(projectBudgetSummaryProvider(projectId));
      },
      child: CustomScrollView(
        slivers: [
          // ── Summary header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SummaryHeader(summary: summary),
          ),

          // ── Empty / line items ──────────────────────────────────────────
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                onAdd: () =>
                    context.push('/projects/$projectId/budget/create'),
              ),
            )
          else
            SliverPadding(
              padding: AppPadding.screen,
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSizes.sm),
                itemBuilder: (ctx, i) {
                  final item = items[i];
                  return Dismissible(
                    key: ValueKey(item.id),
                    direction: DismissDirection.endToStart,
                    background: _DeleteBackground(),
                    confirmDismiss: (_) async {
                      await _deleteItem(ctx, ref, item);
                      return false;
                    },
                    child: BudgetItemCard(
                      item: item,
                      onTap: () => ctx.push(
                        '/projects/$projectId/budget/${item.id}/edit',
                        extra: item,
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
      ),
    );
  }
}

// ── Summary header ────────────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.summary});
  final BudgetSummary? summary;

  String _fmt(double v) => '\$${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    if (summary == null) return const SizedBox.shrink();
    final pct = summary!.estimatedTotal > 0
        ? (summary!.actualTotal / summary!.estimatedTotal).clamp(0.0, 1.0)
        : 0.0;
    final isOver = summary!.isOverBudget;

    return Container(
      padding: AppPadding.screen,
      color: AppColors.deepNavy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spent',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textInverse.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    _fmt(summary!.actualTotal),
                    style: AppTextStyles.h2.copyWith(
                      color: isOver ? AppColors.error : AppColors.textInverse,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Budget',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textInverse.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    _fmt(summary!.estimatedTotal),
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.textInverse,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(
                isOver ? AppColors.error : AppColors.goldAccent,
              ),
            ),
          ),
          if (isOver) ...[
            const SizedBox(height: AppSizes.xs),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.error, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Over budget by ${_fmt(summary!.actualTotal - summary!.estimatedTotal)}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.error),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

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
              Icons.attach_money_outlined,
              size: AppSizes.iconXl,
              color: AppColors.gray400,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'Track your project budget',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Add line items for materials, labor, permits, and more.',
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
              child: const Text('+ Add Item'),
            ),
          ],
        ),
      ),
    );
  }
}

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
            Text("Couldn't load budget",
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
