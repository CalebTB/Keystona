import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/aurora/aurora.dart';




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
          padding: EdgeInsets.symmetric(horizontal: AuroraSpacing.screenPadH).copyWith(top: AuroraSpacing.space3),
          sliver: SliverList.separated(
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: AuroraSpacing.space3),
            itemBuilder: (_, i) => LifespanCard(entry: entries[i]),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AuroraSpacing.space8)),
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
        AuroraSpacing.space5,
        AuroraSpacing.space5,
        AuroraSpacing.space5,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.space5,
        vertical: AuroraSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: AuroraColors.yellowDim,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AuroraColors.yellow.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.savings_outlined, color: AuroraColors.yellow, size: AuroraSpacing.space5),
          const SizedBox(width: AuroraSpacing.space3),
          Expanded(
            child: Text(
              'Est. upcoming replacement costs: $formatted',
              style: AuroraType.body.copyWith(
                color: AuroraColors.yellow,
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
        padding: EdgeInsets.symmetric(horizontal: AuroraSpacing.screenPadH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: AuroraSpacing.space9,
              color: AuroraColors.coral,
            ),
            const SizedBox(height: AuroraSpacing.space5),
            Text(
              'Couldn\'t load lifespan data',
              style: AuroraType.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuroraSpacing.space3),
            Text(
              'Check your connection and try again.',
              style: AuroraType.body.copyWith(
                color: AuroraColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuroraSpacing.space7),
            PrimaryButton(
              label: 'Retry',
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
