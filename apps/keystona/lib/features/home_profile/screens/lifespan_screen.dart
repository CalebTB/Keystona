import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/system_lifespan_entry.dart';
import '../providers/lifespan_provider.dart';
import '../widgets/lifespan_card.dart';
import '../widgets/lifespan_empty_state.dart';
import '../widgets/lifespan_skeleton.dart';

/// Lifespan Tracking screen.
///
/// Shows all active systems sorted by urgency (End of Life → Aging →
/// Healthy → Unknown age). A summary banner at the top shows total
/// estimated replacement cost for non-healthy systems.
class LifespanScreen extends ConsumerWidget {
  const LifespanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final asyncData = ref.watch(lifespanProvider);

    Widget body = asyncData.when(
      loading: () => const LifespanSkeleton(),
      error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(lifespanProvider)),
      data: (entries) {
        if (entries.isEmpty) return const LifespanEmptyState();
        return _LifespanList(entries: entries, ref: ref);
      },
    );

    if (isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Lifespan Tracker'),
        ),
        child: SafeArea(bottom: false, child: body),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Lifespan Tracker')),
      body: body,
    );
  }
}

// ── List with pull-to-refresh ──────────────────────────────────────────────

class _LifespanList extends StatelessWidget {
  const _LifespanList({required this.entries, required this.ref});

  final List<SystemLifespanEntry> entries;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final urgentEntries = entries
        .where((e) => e.isEndOfLife || e.isAging)
        .toList();
    final totalReplacementCost = urgentEntries
        .map((e) => e.estimatedReplacementCost ?? 0.0)
        .fold(0.0, (a, b) => a + b);

    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () => ref.read(lifespanProvider.notifier).refresh(),
        ),

        // ── Replacement cost banner ──────────────────────────────────────
        if (totalReplacementCost > 0)
          SliverToBoxAdapter(
            child: _ReplacementCostBanner(totalCost: totalReplacementCost),
          ),

        // ── System cards ────────────────────────────────────────────────
        SliverPadding(
          padding: AppPadding.screen.copyWith(top: AppSizes.sm),
          sliver: SliverList.separated(
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
            itemBuilder: (_, i) => LifespanCard(entry: entries[i]),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSizes.xl)),
      ],
    );
  }
}

// ── Replacement cost banner ───────────────────────────────────────────────

class _ReplacementCostBanner extends StatelessWidget {
  const _ReplacementCostBanner({required this.totalCost});

  final double totalCost;

  @override
  Widget build(BuildContext context) {
    final formatted = totalCost >= 1000
        ? '\$${(totalCost / 1000).toStringAsFixed(1)}k'
        : '\$${totalCost.toStringAsFixed(0)}';

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.md,
        AppSizes.md,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.savings_outlined, color: AppColors.warning, size: AppSizes.iconMd),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              'Est. upcoming replacement costs: $formatted',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────

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
              size: AppSizes.xxl,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'Couldn\'t load lifespan data',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Check your connection and try again.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.lg),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.deepNavy,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
