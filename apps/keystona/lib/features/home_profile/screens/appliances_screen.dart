import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
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
            right: AppSizes.lg,
            bottom: AppSizes.xl,
            child: FloatingActionButton(
              onPressed: () => context.push(AppRoutes.homeAppliancesAdd),
              backgroundColor: AppColors.deepNavy,
              foregroundColor: AppColors.textInverse,
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
      backgroundColor: AppColors.warmOffWhite,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.homeAppliancesAdd),
        backgroundColor: AppColors.deepNavy,
        foregroundColor: AppColors.textInverse,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        color: AppColors.deepNavy,
        onRefresh: () => ref.read(appliancesProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text('Appliances', style: AppTextStyles.h3),
              floating: true,
              backgroundColor: AppColors.warmOffWhite,
              scrolledUnderElevation: 0,
              elevation: 0,
            ),
            const _ContentSliver(),
            const SliverToBoxAdapter(child: SizedBox(height: AppSizes.xl)),
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
          padding: AppPadding.screen,
          sliver: SliverList.builder(
            itemCount: items.length + (showBanner ? 1 : 0),
            itemBuilder: (context, index) {
              if (showBanner && index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.sm),
                  child: _LimitBanner(count: appliances.length),
                );
              }
              final i = showBanner ? index - 1 : index;
              final item = items[i];
              if (item is _SectionHeader) {
                return Padding(
                  padding: const EdgeInsets.only(
                    top: AppSizes.md,
                    bottom: AppSizes.xs,
                  ),
                  child: Text(
                    item.title,
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.textSecondary),
                  ),
                );
              }
              if (item is _ApplianceItem) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.sm),
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
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 18, color: AppColors.warning),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              "You're using $count of 10 free appliances. Upgrade to PRO for unlimited.",
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: AppColors.warning,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
            ),
            child: Text(
              'Upgrade',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
