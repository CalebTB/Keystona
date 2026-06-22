import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/error_view.dart';
import '../models/insurance_policy.dart';
import '../providers/emergency_hub_provider.dart';
import '../widgets/insurance_empty_state.dart';
import '../widgets/insurance_list_skeleton.dart';
import '../widgets/insurance_policy_card.dart';

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
            onRefresh: () => ref.read(emergencyHubProvider.notifier).refresh(),
          ),
          const _ContentSliver(),
          const SliverToBoxAdapter(
              child: SizedBox(height: AuroraSpacing.space10)),
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
      backgroundColor: AuroraColors.paper,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AuroraColors.ink,
        onPressed: () => context.push(AppRoutes.emergencyInsuranceAdd),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        color: AuroraColors.ink,
        onRefresh: () => ref.read(emergencyHubProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text('Insurance', style: AuroraType.h3),
              floating: true,
              backgroundColor: AuroraColors.paper,
              scrolledUnderElevation: 0,
              elevation: 0,
            ),
            const _ContentSliver(),
            const SliverToBoxAdapter(
                child: SizedBox(height: AuroraSpacing.space10)),
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
      error: (_, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorView(
          message: "Couldn't load insurance policies.",
          onRetry: () => ref.invalidate(emergencyHubProvider),
        ),
      ),
      data: (overview) {
        final policies = overview.policies;
        if (policies.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: InsuranceEmptyState(
              onAddPolicy: () => context.push(AppRoutes.emergencyInsuranceAdd),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.all(AuroraSpacing.screenPadH),
          sliver: SliverList.builder(
            itemCount: policies.length,
            itemBuilder: (_, i) => Padding(
              padding: EdgeInsets.only(
                bottom: i < policies.length - 1 ? AuroraSpacing.space3 : 0,
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
