import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../models/insurance_policy.dart';
import '../providers/emergency_hub_provider.dart';
import '../widgets/insurance_empty_state.dart';
import '../widgets/insurance_list_skeleton.dart';
import '../widgets/insurance_policy_card.dart';

/// Displays the full list of insurance policies for the property.
///
/// iOS: CupertinoPageScaffold + CupertinoSliverNavigationBar with "+" button.
/// Android: Scaffold + SliverAppBar + FloatingActionButton.
class InsuranceListScreen extends ConsumerWidget {
  const InsuranceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return isIOS ? const _IOSLayout() : const _AndroidLayout();
  }
}

// ── iOS layout ────────────────────────────────────────────────────────────────

class _IOSLayout extends ConsumerWidget {
  const _IOSLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Insurance'),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => context.push(AppRoutes.emergencyInsuranceAdd),
              child: const Icon(CupertinoIcons.add),
            ),
          ),
          CupertinoSliverRefreshControl(
            onRefresh: () =>
                ref.read(emergencyHubProvider.notifier).refresh(),
          ),
          const _ContentSliver(),
          const SliverToBoxAdapter(child: SizedBox(height: AppSizes.xl)),
        ],
      ),
    );
  }
}

// ── Android layout ────────────────────────────────────────────────────────────

class _AndroidLayout extends ConsumerWidget {
  const _AndroidLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.deepNavy,
        onPressed: () => context.push(AppRoutes.emergencyInsuranceAdd),
        child: const Icon(Icons.add, color: AppColors.textInverse),
      ),
      body: RefreshIndicator(
        color: AppColors.deepNavy,
        onRefresh: () => ref.read(emergencyHubProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text('Insurance', style: AppTextStyles.h3),
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

// ── Content sliver ────────────────────────────────────────────────────────────

class _ContentSliver extends ConsumerWidget {
  const _ContentSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(emergencyHubProvider);

    return overviewAsync.when(
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: InsuranceListSkeleton(),
      ),
      error: (error, stackTrace) => SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorView(
          message: "Couldn't load insurance policies.",
          onRetry: () => ref.invalidate(emergencyHubProvider),
        ),
      ),
      data: (overview) {
        final policies = overview.policies;
        if (policies.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: InsuranceEmptyState(),
          );
        }
        return SliverPadding(
          padding: AppPadding.screen,
          sliver: SliverList.builder(
            itemCount: policies.length,
            itemBuilder: (_, i) => Padding(
              padding: EdgeInsets.only(
                bottom: i < policies.length - 1 ? AppSizes.sm : 0,
              ),
              child: InsurancePolicyCard(
                policy: policies[i],
                onTap: () => _onPolicyTap(context, policies[i]),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onPolicyTap(BuildContext context, InsurancePolicy policy) {
    context.push(
      AppRoutes.emergencyInsuranceEdit.replaceFirst(':policyId', policy.id),
      extra: policy,
    );
  }
}
