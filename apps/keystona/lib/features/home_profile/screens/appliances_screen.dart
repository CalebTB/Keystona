import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';

import '../../../core/router/app_router.dart';



import '../../../core/widgets/error_view.dart';
import '../../../services/providers/service_providers.dart';
import '../models/appliance.dart';
import '../providers/appliances_provider.dart';
import '../widgets/appliance_card.dart';
import '../widgets/appliance_list_skeleton.dart';
import '../widgets/appliances_empty_state.dart';

const _kFreeLimitWarningAt = 8;

class AppliancesScreen extends ConsumerWidget {
  const AppliancesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return isIOS ? const _IOSLayout() : const _AndroidLayout();
  }
}

class _IOSLayout extends ConsumerWidget {
  const _IOSLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              const CupertinoSliverNavigationBar(
                largeTitle: Text('Appliances'),
                previousPageTitle: 'Home',
              ),
              CupertinoSliverRefreshControl(
                onRefresh: () =>
                    ref.read(appliancesProvider.notifier).refresh(),
              ),
              const _ContentSliver(),
              const SliverToBoxAdapter(child: SizedBox(height: 88)),
            ],
          ),
          Positioned(
            right: AuroraSpacing.space7,
            bottom: AuroraSpacing.space8,
            child: FloatingActionButton(
              onPressed: () => context.push(AppRoutes.homeAppliancesAdd),
              backgroundColor: AuroraColors.coral,
              foregroundColor: AuroraColors.paper,
              elevation: 3,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}

class _AndroidLayout extends ConsumerWidget {
  const _AndroidLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AuroraColors.paper,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.homeAppliancesAdd),
        backgroundColor: AuroraColors.coral,
        foregroundColor: AuroraColors.paper,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        color: AuroraColors.ink,
        onRefresh: () => ref.read(appliancesProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text('Appliances', style: AuroraType.h3),
              floating: true,
              backgroundColor: AuroraColors.paper,
              scrolledUnderElevation: 0,
              elevation: 0,
            ),
            const _ContentSliver(),
            const SliverToBoxAdapter(child: SizedBox(height: AuroraSpacing.space8)),
          ],
        ),
      ),
    );
  }
}

class _ContentSliver extends ConsumerWidget {
  const _ContentSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appliancesAsync = ref.watch(appliancesProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return appliancesAsync.when(
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: ApplianceListSkeleton(),
      ),
      error: (e, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorView(
          message: "Couldn't load your appliances.",
          onRetry: () => ref.read(appliancesProvider.notifier).refresh(),
        ),
      ),
      data: (appliances) {
        if (appliances.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: AppliancesEmptyState(
              onAdd: () => context.push(AppRoutes.homeAppliancesAdd),
            ),
          );
        }
        // Group by category.
        final grouped = <ApplianceCategory, List<Appliance>>{};
        for (final a in appliances) {
          grouped.putIfAbsent(a.category, () => []).add(a);
        }
        final items = <_ListItem>[];
        for (final entry in grouped.entries) {
          items.add(_SectionHeader(entry.key.label));
          for (final a in entry.value) {
            items.add(_ApplianceItem(a));
          }
        }
        final showBanner =
            !isPremium && appliances.length >= _kFreeLimitWarningAt;
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: AuroraSpacing.screenPadH),
          sliver: SliverList.builder(
            itemCount: items.length + (showBanner ? 1 : 0),
            itemBuilder: (context, index) {
              if (showBanner && index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AuroraSpacing.space3),
                  child: _LimitBanner(count: appliances.length),
                );
              }
              final i = showBanner ? index - 1 : index;
              final item = items[i];
              if (item is _SectionHeader) {
                return Padding(
                  padding: const EdgeInsets.only(
                    top: AuroraSpacing.space5,
                    bottom: AuroraSpacing.space1,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AuroraColors.inkSecondary,
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.title.toUpperCase(),
                        style: AuroraType.label
                            .copyWith(color: AuroraColors.inkSecondary),
                      ),
                    ],
                  ),
                );
              }
              if (item is _ApplianceItem) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AuroraSpacing.space3),
                  child: ApplianceCard(appliance: item.appliance),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }
}

abstract class _ListItem {}

class _SectionHeader extends _ListItem {
  _SectionHeader(this.title);
  final String title;
}

class _ApplianceItem extends _ListItem {
  _ApplianceItem(this.appliance);
  final Appliance appliance;
}

class _LimitBanner extends StatelessWidget {
  const _LimitBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.space5,
        vertical: AuroraSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: AuroraColors.yellowDim,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AuroraColors.yellow.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 18, color: AuroraColors.yellow),
          const SizedBox(width: AuroraSpacing.space3),
          Expanded(
            child: Text(
              "You're using $count of 10 free appliances. Upgrade to PRO for unlimited.",
              style:
                  AuroraType.bodySm.copyWith(color: AuroraColors.yellow),
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: AuroraColors.yellow,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
            ),
            child: Text(
              'Upgrade',
              style: AuroraType.label.copyWith(
                color: AuroraColors.yellow,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
