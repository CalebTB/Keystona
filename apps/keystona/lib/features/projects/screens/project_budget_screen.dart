import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/project_budget_item.dart';
import '../models/project_phase.dart';
import '../providers/project_budget_provider.dart';
import '../providers/project_detail_provider.dart';
import '../providers/project_phases_provider.dart';
import '../widgets/budget_item_card.dart';
import '../widgets/budget_skeleton.dart';

/// Budget screen — routes to Editorial Summary (active) or Timeline (completed).
///
/// Route: /projects/:projectId/budget
class ProjectBudgetScreen extends ConsumerWidget {
  const ProjectBudgetScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProject = ref.watch(projectDetailProvider(projectId));
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    void onAdd() => context.push('/projects/$projectId/budget/create');

    final project = asyncProject.value;
    final isFinished = project?.status == 'completed' || project?.status == 'cancelled';

    final body = asyncProject.when(
      loading: () => const BudgetSkeleton(),
      error: (_, _) => _ErrorState(
        onRetry: () => ref.invalidate(projectDetailProvider(projectId)),
      ),
      data: (p) {
        final finished = p.status == 'completed' || p.status == 'cancelled';
        return finished
            ? _BudgetTimelineView(
                projectId: projectId,
                isCancelled: p.status == 'cancelled',
              )
            : _BudgetEditorialView(projectId: projectId, onAdd: onAdd);
      },
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Budget'),
          trailing: isFinished
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {},
                  child: const Icon(CupertinoIcons.share),
                )
              : CupertinoButton(
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
      floatingActionButton: isFinished
          ? null
          : FloatingActionButton(
              onPressed: onAdd,
              backgroundColor: AppColors.accent,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

Color _categoryColor(String cat) => switch (cat) {
      'labor' => AppColors.slate,
      'materials' => AppColors.teal,
      'fixtures' => AppColors.plum,
      'permits' => AppColors.sand,
      'equipment_rental' => AppColors.sandAmber,
      'design' => AppColors.olive,
      _ => AppColors.gray500,
    };

String _categoryDisplayName(String cat) => switch (cat) {
      'labor' => 'Labor',
      'materials' => 'Materials',
      'fixtures' => 'Fixtures',
      'permits' => 'Permits',
      'equipment_rental' => 'Equipment',
      'design' => 'Design',
      _ => cat,
    };

// ── Variant A · Editorial Summary ─────────────────────────────────────────────

class _BudgetEditorialView extends ConsumerWidget {
  const _BudgetEditorialView({
    required this.projectId,
    required this.onAdd,
  });

  final String projectId;
  final VoidCallback onAdd;

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

    final notifier = ref.read(projectBudgetProvider(projectId).notifier);
    try {
      await notifier.deleteItem(item.id);
      if (!context.mounted) return;
      SnackbarService.showSuccess(context, 'Item deleted.');
    } catch (_) {
      if (!context.mounted) return;
      SnackbarService.showError(context, 'Could not delete item.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(projectBudgetProvider(projectId));
    final asyncSummary = ref.watch(projectBudgetSummaryProvider(projectId));
    final asyncPhases = ref.watch(projectPhasesProvider(projectId));

    return asyncItems.when(
      loading: () => const BudgetSkeleton(),
      error: (_, _) => _ErrorState(
        onRetry: () => ref.invalidate(projectBudgetProvider(projectId)),
      ),
      data: (items) {
        final summary = asyncSummary.value;
        final phases = asyncPhases.value ?? [];

        return CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                ref.invalidate(projectBudgetProvider(projectId));
                ref.invalidate(projectBudgetSummaryProvider(projectId));
              },
            ),

            // ── Screen header ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: AppPadding.screen.copyWith(bottom: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ScreenHeader(phases: phases),
                    const SizedBox(height: AppSizes.xs),
                  ],
                ),
              ),
            ),

            // ── Hero strip ────────────────────────────────────────────────
            if (summary != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppPadding.screen.copyWith(top: 0, bottom: 0),
                  child: _EditorialHero(summary: summary, phases: phases),
                ),
              ),

            // ── Category cards ────────────────────────────────────────────
            if (summary != null && summary.categoryBreakdown.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppPadding.screen.copyWith(top: AppSizes.lg, bottom: 0),
                  child: _SectionLabel(
                    label: 'BY CATEGORY',
                    dotColor: AppColors.accent,
                  ),
                ),
              ),
              SliverPadding(
                padding: AppPadding.screen.copyWith(top: AppSizes.xs, bottom: 0),
                sliver: SliverList.separated(
                  itemCount: summary.categoryBreakdown.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSizes.sm - 2),
                  itemBuilder: (ctx, i) {
                    final row = summary.categoryBreakdown[i];
                    final categoryItems = items
                        .where((item) => item.category == row.category)
                        .toList();
                    return _CategoryCard(
                      row: row,
                      totalActual: summary.actualTotal,
                      items: categoryItems,
                      onItemTap: (item) => ctx.push(
                        '/projects/$projectId/budget/${item.id}/edit',
                        extra: item,
                      ),
                    );
                  },
                ),
              ),
            ],

            // ── Smart Insight upsell ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: AppPadding.screen.copyWith(
                  top: AppSizes.md,
                  bottom: 0,
                ),
                child: const _InsightUpsell(),
              ),
            ),

            // ── All line items ────────────────────────────────────────────
            if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(onAdd: onAdd),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppPadding.screen.copyWith(
                    top: AppSizes.lg,
                    bottom: 0,
                  ),
                  child: _SectionLabel(
                    label: 'ALL ITEMS',
                    dotColor: AppColors.gray400,
                  ),
                ),
              ),
              SliverPadding(
                padding: AppPadding.screen.copyWith(top: AppSizes.xs),
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
            ],

            const SliverToBoxAdapter(
              child: SizedBox(height: AppSizes.xxl + AppSizes.xl),
            ),
          ],
        );
      },
    );
  }
}

// ── Variant B · Timeline Spend ────────────────────────────────────────────────

class _BudgetTimelineView extends ConsumerWidget {
  const _BudgetTimelineView({
    required this.projectId,
    required this.isCancelled,
  });

  final String projectId;
  final bool isCancelled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(projectBudgetProvider(projectId));
    final asyncSummary = ref.watch(projectBudgetSummaryProvider(projectId));
    final asyncPhases = ref.watch(projectPhasesProvider(projectId));

    return asyncItems.when(
      loading: () => const BudgetSkeleton(),
      error: (_, _) => _ErrorState(
        onRetry: () => ref.invalidate(projectBudgetProvider(projectId)),
      ),
      data: (items) {
        final summary = asyncSummary.value;
        final phases = List<ProjectPhase>.from(asyncPhases.value ?? [])
          ..removeWhere((p) => p.deletedAt != null)
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        if (items.isEmpty) {
          return _TimelineEmptyState(isCancelled: isCancelled);
        }

        return CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                ref.invalidate(projectBudgetProvider(projectId));
                ref.invalidate(projectBudgetSummaryProvider(projectId));
              },
            ),

            // ── Screen header ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: AppPadding.screen.copyWith(bottom: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TimelineHeader(isCancelled: isCancelled),
                    const SizedBox(height: AppSizes.xs),
                  ],
                ),
              ),
            ),

            // ── Summary card ──────────────────────────────────────────────
            if (summary != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppPadding.screen.copyWith(top: 0, bottom: 0),
                  child: _TimelineSummaryCard(
                    summary: summary,
                    isCancelled: isCancelled,
                  ),
                ),
              ),

            // ── Phase timeline ────────────────────────────────────────────
            if (phases.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppPadding.screen.copyWith(
                    top: AppSizes.lg,
                    bottom: 0,
                  ),
                  child: _SectionLabel(
                    label: 'SPEND BY PHASE',
                    dotColor: AppColors.accent,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppPadding.screen.copyWith(
                    top: AppSizes.xs,
                    bottom: 0,
                  ),
                  child: _PhaseTimeline(phases: phases),
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      },
    );
  }
}

// ── Timeline header ────────────────────────────────────────────────────────────

class _TimelineHeader extends StatelessWidget {
  const _TimelineHeader({required this.isCancelled});
  final bool isCancelled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCancelled ? AppColors.accent : AppColors.olive,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isCancelled ? 'CANCELLED · PARTIAL SPEND' : 'SPEND ACROSS PHASES',
          style: AppTextStyles.monoSection.copyWith(
            color: isCancelled ? AppColors.accent : AppColors.gray500,
          ),
        ),
      ],
    );
  }
}

// ── Summary card with stacked bar + legend ────────────────────────────────────

class _TimelineSummaryCard extends StatelessWidget {
  const _TimelineSummaryCard({
    required this.summary,
    required this.isCancelled,
  });

  final BudgetSummary summary;
  final bool isCancelled;

  static final _fmt =
      NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final isOver =
        summary.estimatedTotal > 0 && summary.actualTotal > summary.estimatedTotal;
    final isUnder =
        summary.estimatedTotal > 0 && summary.actualTotal < summary.estimatedTotal;
    final difference = (summary.estimatedTotal - summary.actualTotal).abs();

    final remainingLabel = isCancelled
        ? 'UNSPENT'
        : isOver
            ? 'OVER BUDGET'
            : isUnder
                ? 'UNDER BUDGET'
                : 'REMAINING';
    final remainingColor = isCancelled
        ? AppColors.textPrimary
        : isOver
            ? AppColors.accent
            : isUnder
                ? AppColors.olive
                : AppColors.textPrimary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Totals row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL SPENT',
                      style: AppTextStyles.monoTiny
                          .copyWith(color: AppColors.gray500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _fmt.format(summary.actualTotal),
                      style: AppTextStyles.displayMedium,
                    ),
                    if (summary.estimatedTotal > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        'of ${_fmt.format(summary.estimatedTotal)} · '
                        '${summary.totalItems} items',
                        style: AppTextStyles.monoLabel
                            .copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    remainingLabel,
                    style: AppTextStyles.monoTiny
                        .copyWith(color: AppColors.gray500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _fmt.format(difference),
                    style: AppTextStyles.monoDisplay.copyWith(
                      color: remainingColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Stacked bar
          if (summary.categoryBreakdown.isNotEmpty &&
              summary.actualTotal > 0) ...[
            const SizedBox(height: 14),
            _StackedCategoryBar(
              rows: summary.categoryBreakdown,
              total: summary.actualTotal,
            ),
          ],

          // Legend
          if (summary.categoryBreakdown.isNotEmpty) ...[
            const SizedBox(height: 10),
            _LegendGrid(rows: summary.categoryBreakdown),
          ],
        ],
      ),
    );
  }
}

// ── Stacked category bar ──────────────────────────────────────────────────────

class _StackedCategoryBar extends StatelessWidget {
  const _StackedCategoryBar({required this.rows, required this.total});

  final List<BudgetCategoryRow> rows;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _semanticLabel(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: SizedBox(
          height: 18,
          child: Row(
            children: rows.map((row) {
              final flex = total > 0
                  ? ((row.actual / total) * 1000).round().clamp(1, 1000)
                  : 0;
              return Expanded(
                flex: flex,
                child: Container(color: _categoryColor(row.category)),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _semanticLabel() {
    if (total == 0) return 'No spending data';
    final parts = rows.map((r) {
      final pct = (r.actual / total * 100).round();
      return '$pct% ${_categoryDisplayName(r.category)}';
    }).join(', ');
    return 'Spending breakdown: $parts';
  }
}

// ── Legend grid (2-column) ────────────────────────────────────────────────────

class _LegendGrid extends StatelessWidget {
  const _LegendGrid({required this.rows});

  final List<BudgetCategoryRow> rows;

  static final _fmt =
      NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final pairs = <(BudgetCategoryRow, BudgetCategoryRow?)>[];
    for (int i = 0; i < rows.length; i += 2) {
      pairs.add((rows[i], i + 1 < rows.length ? rows[i + 1] : null));
    }

    return Column(
      children: pairs.map((pair) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Expanded(child: _legendItem(pair.$1)),
              const SizedBox(width: 10),
              pair.$2 != null
                  ? Expanded(child: _legendItem(pair.$2!))
                  : const Expanded(child: SizedBox()),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _legendItem(BudgetCategoryRow row) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _categoryColor(row.category),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            _categoryDisplayName(row.category),
            style: AppTextStyles.monoTiny.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
              letterSpacing: 0,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          _fmt.format(row.actual),
          style: AppTextStyles.monoTiny.copyWith(
            color: AppColors.textPrimary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

// ── Phase timeline ────────────────────────────────────────────────────────────

class _PhaseTimeline extends StatelessWidget {
  const _PhaseTimeline({required this.phases});

  final List<ProjectPhase> phases;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(phases.length, (i) {
        return _PhaseRow(
          phase: phases[i],
          number: i + 1,
          isLast: i == phases.length - 1,
        );
      }),
    );
  }
}

// ── Phase row (dot + connecting line + card) ──────────────────────────────────

class _PhaseRow extends StatelessWidget {
  const _PhaseRow({
    required this.phase,
    required this.number,
    required this.isLast,
  });

  final ProjectPhase phase;
  final int number;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isDone = phase.status == 'completed';
    final isSkipped =
        phase.status == 'planning' || phase.status == 'cancelled';

    final dotBg = isDone ? AppColors.olive : AppColors.warmFill;
    final lineColor = isDone ? AppColors.olive : AppColors.warmFill;

    Widget content = Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dot + vertical connecting line
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotBg,
                    ),
                    child: isDone
                        ? const Icon(Icons.check,
                            size: 14, color: Colors.white)
                        : Center(
                            child: Text(
                              '$number',
                              style: AppTextStyles.monoSection.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 11,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: ExcludeSemantics(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          decoration: BoxDecoration(
                            color: lineColor,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PhaseCard(phase: phase),
            ),
          ],
        ),
      ),
    );

    if (isSkipped) {
      content = Opacity(opacity: 0.4, child: content);
    }

    return content;
  }
}

// ── Phase card ────────────────────────────────────────────────────────────────

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({required this.phase});

  final ProjectPhase phase;

  static final _dateFmt = DateFormat('MMM d');

  @override
  Widget build(BuildContext context) {
    final isDone = phase.status == 'completed';
    final isSkipped =
        phase.status == 'planning' || phase.status == 'cancelled';

    // Date label
    String dateLabel;
    Color dateLabelColor;
    if (isDone && phase.actualEndDate != null) {
      if (phase.plannedEndDate != null &&
          phase.actualEndDate!.isAfter(phase.plannedEndDate!)) {
        final days =
            phase.actualEndDate!.difference(phase.plannedEndDate!).inDays;
        dateLabel = 'OVER · ${days}D LATE';
        dateLabelColor = AppColors.accent;
      } else {
        dateLabel = 'DONE · ${_dateFmt.format(phase.actualEndDate!).toUpperCase()}';
        dateLabelColor = AppColors.olive;
      }
    } else if (phase.plannedEndDate != null) {
      dateLabel = _dateFmt.format(phase.plannedEndDate!).toUpperCase();
      dateLabelColor = AppColors.textTertiary;
    } else {
      dateLabel = '—';
      dateLabelColor = AppColors.textTertiary;
    }

    // Variance badge for skipped phases
    Widget? badge;
    if (isSkipped) {
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.warmFill,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'NOT STARTED',
          style: AppTextStyles.monoTiny.copyWith(
            color: AppColors.textTertiary,
            fontSize: 9,
          ),
        ),
      );
    }

    return Semantics(
      label: '${phase.name}, $dateLabel',
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phase name + date label
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    phase.name,
                    style: GoogleFonts.fraunces(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateLabel,
                  style: AppTextStyles.monoTiny.copyWith(
                    color: dateLabelColor,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
            if (badge != null) ...[
              const SizedBox(height: 6),
              badge,
            ],
          ],
        ),
      ),
    );
  }
}

// ── Timeline empty state ──────────────────────────────────────────────────────

class _TimelineEmptyState extends StatelessWidget {
  const _TimelineEmptyState({required this.isCancelled});
  final bool isCancelled;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppPadding.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: AppSizes.iconXl,
              color: AppColors.gray400,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              isCancelled
                  ? 'No spending recorded'
                  : 'No budget items tracked',
              style: AppTextStyles.displaySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'No budget items were tracked for this project.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Screen header ─────────────────────────────────────────────────────────────

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({required this.phases});
  final List<ProjectPhase> phases;

  @override
  Widget build(BuildContext context) {
    final activePhases =
        phases.where((p) => p.deletedAt == null && p.status != 'cancelled').toList();
    final currentIndex = () {
      final idx = activePhases.indexWhere((p) => p.status == 'in_progress');
      if (idx >= 0) return idx + 1;
      final lastDone = activePhases.lastIndexWhere((p) => p.status == 'completed');
      return lastDone >= 0 ? lastDone + 1 : 0;
    }();

    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          activePhases.isNotEmpty
              ? 'ACTIVE PROJECT · PHASE $currentIndex OF ${activePhases.length}'
              : 'ACTIVE PROJECT',
          style: AppTextStyles.monoSection.copyWith(
            color: AppColors.gray500,
          ),
        ),
      ],
    );
  }
}

// ── Editorial hero strip ──────────────────────────────────────────────────────

class _EditorialHero extends StatelessWidget {
  const _EditorialHero({required this.summary, required this.phases});

  final BudgetSummary summary;
  final List<ProjectPhase> phases;

  static final _moneyFmt =
      NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 0);

  String _fmt(double v) => _moneyFmt.format(v);

  @override
  Widget build(BuildContext context) {
    final estimated = summary.estimatedTotal;
    final actual = summary.actualTotal;
    final remaining = summary.remaining;

    final spentFraction =
        estimated > 0 ? (actual / estimated).clamp(0.0, 1.0) : 0.0;
    final spentPct = estimated > 0 ? actual / estimated * 100 : 0.0;

    // Phase pace
    final activePhases = phases
        .where((p) => p.deletedAt == null && p.status != 'cancelled')
        .toList();
    double phaseFraction = spentFraction;
    String paceLabel = 'On track';

    if (activePhases.isNotEmpty) {
      int currentIdx =
          activePhases.indexWhere((p) => p.status == 'in_progress');
      if (currentIdx < 0) {
        currentIdx =
            activePhases.lastIndexWhere((p) => p.status == 'completed');
      }
      if (currentIdx < 0) currentIdx = 0;
      phaseFraction =
          ((currentIdx + 0.5) / activePhases.length).clamp(0.0, 1.0);
      final phasePct = phaseFraction * 100;

      if (spentPct > phasePct + 10) {
        paceLabel = 'Behind';
      } else if (spentPct < phasePct - 10) {
        paceLabel = 'Ahead';
      }
    }

    final isBehind = paceLabel == 'Behind';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.deepNavy,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow
          Text(
            estimated > 0
                ? 'SPENT OF ${_fmt(estimated)}'
                : 'TOTAL SPENT',
            style: AppTextStyles.monoTiny.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),

          // Big number
          Text(
            _fmt(actual),
            style: GoogleFonts.fraunces(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              height: 1,
              color: AppColors.textInverse,
            ),
          ),
          const SizedBox(height: 4),

          // Subline: remaining · percent used
          Text.rich(
            TextSpan(
              style: AppTextStyles.monoLabel.copyWith(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11,
              ),
              children: [
                TextSpan(
                  text: _fmt(remaining.abs()),
                  style: const TextStyle(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                    text: remaining >= 0 ? ' remaining · ' : ' over · '),
                TextSpan(
                  text: '${spentPct.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' used'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Progress bar + pace marker
          _HeroProgressBar(
            spentFraction: spentFraction,
            phaseFraction: phaseFraction,
          ),
          const SizedBox(height: 12),

          // 3 mini-stats
          Row(
            children: [
              _MiniStat(
                label: 'PACE',
                value: paceLabel,
                valueColor:
                    isBehind ? AppColors.sand : AppColors.textInverse,
              ),
              _MiniDivider(),
              _MiniStat(
                label: 'OVER BUDGET',
                value: '${summary.overBudgetCount}',
                valueColor: summary.overBudgetCount > 0
                    ? AppColors.sand
                    : AppColors.textInverse,
              ),
              _MiniDivider(),
              _MiniStat(
                label: 'ITEMS',
                value: '${summary.totalItems}',
                valueColor: AppColors.textInverse,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Hero progress bar with pace marker ───────────────────────────────────────

class _HeroProgressBar extends StatelessWidget {
  const _HeroProgressBar({
    required this.spentFraction,
    required this.phaseFraction,
  });

  final double spentFraction;
  final double phaseFraction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;
        final markerX = (barWidth * phaseFraction).clamp(2.0, barWidth - 2.0);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Track + gradient fill
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Stack(
                  children: [
                    Container(color: Colors.white.withValues(alpha: 0.08)),
                    FractionallySizedBox(
                      widthFactor: spentFraction,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.oliveLight, AppColors.sand],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Pace marker
            Positioned(
              left: markerX - 1,
              top: -3,
              child: Container(
                width: 2,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Mini stat cell ────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.monoTiny.copyWith(
              color: Colors.white.withValues(alpha: 0.4),
              letterSpacing: 0.6,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTextStyles.monoLabel.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
      color: Colors.white.withValues(alpha: 0.1),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.dotColor});

  final String label;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.monoSection.copyWith(
            color: AppColors.gray500,
          ),
        ),
      ],
    );
  }
}

// ── Category card (expandable) ────────────────────────────────────────────────

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({
    required this.row,
    required this.totalActual,
    required this.items,
    required this.onItemTap,
  });

  final BudgetCategoryRow row;
  final double totalActual;
  final List<ProjectBudgetItem> items;
  final void Function(ProjectBudgetItem) onItemTap;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _expanded = false;

  static final _moneyFmt =
      NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 0);

  String _fmt(double v) => _moneyFmt.format(v);

  static Color _dotColor(String cat) => _categoryColor(cat);

  (String label, Color bg, Color text) _pill(BudgetCategoryRow row) {
    if (row.pendingCount > 0) {
      return (
        '${row.pendingCount} PENDING',
        AppColors.sandDim,
        AppColors.sandAmber,
      );
    }
    if (row.estimated > 0 && row.actual > row.estimated) {
      final over = row.actual - row.estimated;
      return ('+${_fmt(over)} OVER', AppColors.accentDim, AppColors.accent);
    }
    if (row.estimated > 0 && row.actual <= row.estimated * 0.95) {
      return ('UNDER EST.', AppColors.oliveDim, AppColors.olive);
    }
    return ('ON TRACK', AppColors.slateDim, AppColors.slate);
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final color = _dotColor(row.category);
    final isOver = row.estimated > 0 && row.actual > row.estimated;
    final barColor = isOver ? AppColors.accent : color;
    final barFraction = row.estimated > 0
        ? (row.actual / row.estimated).clamp(0.0, 1.0)
        : 0.0;
    final pctOfSpent =
        widget.totalActual > 0 ? (row.actual / widget.totalActual * 100) : 0.0;
    final (pillLabel, pillBg, pillText) = _pill(row);
    final hasItems = widget.items.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header (always visible, tappable) ──────────────────────────
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: hasItems
                  ? () => setState(() => _expanded = !_expanded)
                  : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: dot + name | amount + chevron
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: color),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            row.category.budgetCategoryLabel,
                            style: GoogleFonts.fraunces(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          _fmt(row.actual),
                          style: AppTextStyles.monoLabel.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isOver
                                ? AppColors.accent
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (hasItems) ...[
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            turns: _expanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(
                              Icons.keyboard_arrow_down,
                              size: 18,
                              color: AppColors.gray400,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        height: 5,
                        child: Stack(
                          children: [
                            Container(color: AppColors.warmInset),
                            FractionallySizedBox(
                              widthFactor: barFraction,
                              child: Container(color: barColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Footer: meta | status pill
                    Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: AppTextStyles.monoTiny.copyWith(
                                color: AppColors.gray500,
                                fontSize: 10,
                                letterSpacing: 0.3,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      '${pctOfSpent.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                    text:
                                        ' of spent · est. ${_fmt(row.estimated)}'),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: pillBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            pillLabel,
                            style: AppTextStyles.monoTiny.copyWith(
                              color: pillText,
                              letterSpacing: 0.6,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Expandable items list ───────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _expanded
                ? Column(
                    children: [
                      Container(height: 1, color: AppColors.border),
                      ...widget.items.map(
                        (item) => _CategoryItemRow(
                          item: item,
                          categoryColor: color,
                          onTap: () => widget.onItemTap(item),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Item row inside expanded category ─────────────────────────────────────────

class _CategoryItemRow extends StatelessWidget {
  const _CategoryItemRow({
    required this.item,
    required this.categoryColor,
    required this.onTap,
  });

  final ProjectBudgetItem item;
  final Color categoryColor;
  final VoidCallback onTap;

  static final _moneyFmt =
      NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 0);

  String _fmt(double v) => _moneyFmt.format(v);

  @override
  Widget build(BuildContext context) {
    final hasActual = item.actualCost > 0;
    final displayCost = hasActual ? item.actualCost : item.estimatedCost;
    final isOver =
        hasActual && item.estimatedCost > 0 && item.actualCost > item.estimatedCost;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              // Paid dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isPaid ? AppColors.olive : Colors.transparent,
                  border: item.isPaid
                      ? null
                      : Border.all(color: AppColors.borderStrong, width: 1.5),
                ),
              ),
              const SizedBox(width: 10),

              // Name + vendor
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (item.vendor != null && item.vendor!.isNotEmpty)
                      Text(
                        item.vendor!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                  ],
                ),
              ),

              // Amount + est label
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _fmt(displayCost),
                    style: AppTextStyles.monoLabel.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color:
                          isOver ? AppColors.accent : AppColors.textPrimary,
                    ),
                  ),
                  if (hasActual && item.estimatedCost > 0)
                    Text(
                      'est. ${_fmt(item.estimatedCost)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  size: 16, color: AppColors.gray400),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Smart Insight upsell (free tier) ─────────────────────────────────────────

class _InsightUpsell extends StatelessWidget {
  const _InsightUpsell();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warmFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderStrong, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 18,
            color: AppColors.sand,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unlock budget insights',
                  style: GoogleFonts.fraunces(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Smart Scan flags overages, missing receipts, and pacing issues automatically — included with Premium.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.gray500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
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
              style: AppTextStyles.displaySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Add line items to monitor spending against your budget. See totals, categories, and how actual costs compare to estimates.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.xl),
            FilledButton(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: AppPadding.button,
              ),
              child: const Text('+ Start Tracking'),
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
                style: AppTextStyles.displaySmall,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSizes.lg),
            FilledButton(
              onPressed: onRetry,
              style:
                  FilledButton.styleFrom(backgroundColor: AppColors.accent),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
