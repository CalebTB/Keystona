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
import '../../../services/supabase_service.dart';
import '../models/project_budget_item.dart';
import '../models/project_phase.dart';
import '../providers/project_budget_provider.dart';
import '../providers/project_detail_provider.dart';
import '../providers/project_phases_provider.dart';
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

    final body = asyncProject.when(
      loading: () => const BudgetSkeleton(),
      error: (_, _) => _ErrorState(
        onRetry: () => ref.invalidate(projectDetailProvider(projectId)),
      ),
      data: (_) => _BudgetEditorialView(projectId: projectId, onAdd: onAdd),
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

// ── Variant A · Editorial Summary ─────────────────────────────────────────────

class _BudgetEditorialView extends ConsumerWidget {
  const _BudgetEditorialView({
    required this.projectId,
    required this.onAdd,
  });

  final String projectId;
  final VoidCallback onAdd;

  Future<void> _markItemPaid(
    BuildContext context,
    WidgetRef ref,
    ProjectBudgetItem item,
  ) async {
    if (item.isPaid) return;
    try {
      await ref
          .read(projectBudgetProvider(projectId).notifier)
          .updateItem(item.id, {'is_paid': true});
    } catch (_) {
      if (!context.mounted) return;
      SnackbarService.showError(context, 'Could not mark item as paid.');
    }
  }

  Future<void> _editBudget(
    BuildContext context,
    WidgetRef ref,
    double currentEstimate,
  ) async {
    final ctrl = TextEditingController(
      text: currentEstimate > 0 ? currentEstimate.toStringAsFixed(0) : '',
    );
    double? newValue;

    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Edit Total Budget'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Material(
            type: MaterialType.transparency,
            child: TextField(
              controller: ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                prefixText: r'$ ',
                hintText: '0',
              ),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              newValue = double.tryParse(ctrl.text.trim());
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.dispose());
    if (newValue == null || !context.mounted) return;

    try {
      await SupabaseService.client
          .from('projects')
          .update({'estimated_budget': newValue})
          .eq('id', projectId);
      if (!context.mounted) return;
      ref.invalidate(projectDetailProvider(projectId));
      ref.invalidate(projectBudgetSummaryProvider(projectId));
    } catch (_) {
      if (!context.mounted) return;
      SnackbarService.showError(context, 'Could not update budget.');
    }
  }

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
                  child: _EditorialHero(
                    summary: summary,
                    phases: phases,
                    onEditBudget: () =>
                        _editBudget(context, ref, summary.estimatedTotal),
                  ),
                ),
              ),

            // ── Empty state ───────────────────────────────────────────────
            if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(onAdd: onAdd),
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
                        .toList()
                      ..sort((a, b) {
                        if (a.isPaid == b.isPaid) return 0;
                        return a.isPaid ? 1 : -1; // unpaid first
                      });
                    return _CategoryCard(
                      key: ValueKey(row.category),
                      row: row,
                      items: categoryItems,
                      onItemTap: (item) => ctx.push(
                        '/projects/$projectId/budget/${item.id}/edit',
                        extra: item,
                      ),
                      onItemMarkPaid: (item) =>
                          _markItemPaid(ctx, ref, item),
                      onItemDelete: (item) => _deleteItem(ctx, ref, item),
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

            const SliverToBoxAdapter(
              child: SizedBox(height: AppSizes.xxl + AppSizes.xl),
            ),
          ],
        );
      },
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
  const _EditorialHero({
    required this.summary,
    required this.phases,
    required this.onEditBudget,
  });

  final BudgetSummary summary;
  final List<ProjectPhase> phases;
  final VoidCallback onEditBudget;

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
          // Eyebrow + edit budget tap
          GestureDetector(
            onTap: onEditBudget,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Text(
                  estimated > 0
                      ? 'SPENT OF ${_fmt(estimated)}'
                      : 'NO BUDGET SET · TAP TO SET',
                  style: AppTextStyles.monoTiny.copyWith(
                    color: estimated > 0
                        ? Colors.white.withValues(alpha: 0.5)
                        : AppColors.sand.withValues(alpha: 0.85),
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.edit_outlined,
                  size: 12,
                  color: estimated > 0
                      ? Colors.white.withValues(alpha: 0.35)
                      : AppColors.sand.withValues(alpha: 0.6),
                ),
              ],
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
                  style: TextStyle(
                    color: remaining < 0 ? AppColors.accent : AppColors.textInverse,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                    text: remaining >= 0 ? ' remaining · ' : ' over budget · '),
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
                label: 'COMMITTED',
                value: _fmt(summary.committedTotal),
                valueColor: summary.committedTotal > summary.estimatedTotal && summary.estimatedTotal > 0
                    ? AppColors.sand
                    : AppColors.textInverse,
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
    super.key,
    required this.row,
    required this.items,
    required this.onItemTap,
    required this.onItemMarkPaid,
    required this.onItemDelete,
  });

  final BudgetCategoryRow row;
  final List<ProjectBudgetItem> items;
  final void Function(ProjectBudgetItem) onItemTap;
  final void Function(ProjectBudgetItem) onItemMarkPaid;
  final void Function(ProjectBudgetItem) onItemDelete;

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
    // % of the category's own estimated budget that has been spent
    final pctOfSpent =
        row.estimated > 0 ? (row.actual / row.estimated * 100).clamp(0.0, 999.0) : 0.0;
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

                    // Progress bar — hidden when no estimate set
                    if (row.estimated > 0) ...[
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
                    ] else
                      const SizedBox(height: 6),

                    // Footer: meta | status pill
                    Row(
                      children: [
                        Expanded(
                          child: row.estimated > 0
                              ? Text.rich(
                                  TextSpan(
                                    style: AppTextStyles.monoTiny.copyWith(
                                      color: AppColors.gray500,
                                      fontSize: 10,
                                      letterSpacing: 0.3,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '${pctOfSpent.toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      TextSpan(
                                          text: ' of est. ${_fmt(row.estimated)}'),
                                    ],
                                  ),
                                )
                              : Text(
                                  'No estimate set',
                                  style: AppTextStyles.monoTiny.copyWith(
                                    color: AppColors.gray400,
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Container(
                            key: ValueKey(pillLabel),
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
                        (item) => Dismissible(
                          key: ValueKey(item.id),
                          direction: DismissDirection.horizontal,
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              if (!item.isPaid) widget.onItemMarkPaid(item);
                            } else {
                              widget.onItemDelete(item);
                            }
                            return false; // provider refresh updates list
                          },
                          background: const _PaidBackground(),
                          secondaryBackground: _DeleteBackground(),
                          child: _CategoryItemRow(
                            item: item,
                            categoryColor: color,
                            onTap: () => widget.onItemTap(item),
                          ),
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
              // Paid dot — animates when item flips paid
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
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

class _PaidBackground extends StatelessWidget {
  const _PaidBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: AppSizes.lg),
      color: AppColors.olive,
      child: const Icon(Icons.check_circle_outline, color: Colors.white),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSizes.lg),
      color: AppColors.error,
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
