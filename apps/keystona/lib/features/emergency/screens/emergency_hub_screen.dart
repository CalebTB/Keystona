import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../providers/emergency_hub_provider.dart';
import '../widgets/contacts_section.dart';
import '../widgets/emergency_hub_skeleton.dart';
import '../widgets/insurance_section.dart';
import '../widgets/shutoff_card.dart';

/// Emergency Hub main screen — lives at [AppRoutes.emergency].
///
/// Accessed via a quick-action button on the Home tab (NOT a bottom nav tab).
///
/// Shows:
///   • Three utility shutoff cards (Water / Gas / Electrical) with completion status
///   • Emergency contacts preview (favorites, "See all" link)
///   • Insurance quick reference (policy summaries, "See all" link)
///   • "Last synced" timestamp stub (implemented by #50 Offline Sync)
///
/// Adaptive layout:
///   iOS  → CupertinoPageScaffold + CupertinoSliverNavigationBar (large title)
///   Android → Scaffold + SliverAppBar
class EmergencyHubScreen extends ConsumerWidget {
  const EmergencyHubScreen({super.key});

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
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Emergency Hub'),
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
      body: RefreshIndicator(
        color: AppColors.deepNavy,
        onRefresh: () => ref.read(emergencyHubProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text('Emergency Hub', style: AppTextStyles.h3),
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
        child: EmergencyHubSkeleton(),
      ),
      error: (error, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorView(
          message: "Couldn't load Emergency Hub.",
          onRetry: () => ref.read(emergencyHubProvider.notifier).refresh(),
        ),
      ),
      data: (overview) => SliverPadding(
        padding: AppPadding.screen,
        sliver: SliverList.list(
          children: [
            // ── Utility Shutoffs ────────────────────────────────────────────
            Text(
              'Utility Shutoffs',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            ShutoffCard(
              utilityType: 'water',
              shutoff: overview.shutoffFor('water'),
              onTap: () => context.push(
                AppRoutes.emergencyShutoffDetail.replaceFirst(':type', 'water'),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            ShutoffCard(
              utilityType: 'gas',
              shutoff: overview.shutoffFor('gas'),
              onTap: () => context.push(
                AppRoutes.emergencyShutoffDetail.replaceFirst(':type', 'gas'),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            ShutoffCard(
              utilityType: 'electrical',
              shutoff: overview.shutoffFor('electrical'),
              onTap: () => context.push(
                AppRoutes.emergencyShutoffDetail
                    .replaceFirst(':type', 'electrical'),
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Emergency Contacts ──────────────────────────────────────────
            ContactsSection(
              favorites: overview.favoriteContacts,
              totalCount: overview.totalContactCount,
              onSeeAll: () => context.push(AppRoutes.emergencyContacts),
              onAddContact: () =>
                  context.push(AppRoutes.emergencyContactsAdd),
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Insurance ───────────────────────────────────────────────────
            InsuranceSection(
              policies: overview.policies,
              onSeeAll: () => context.push(AppRoutes.emergencyInsurance),
              onAddPolicy: () => context.push(AppRoutes.emergencyInsurance),
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Last synced timestamp (stub for #50) ────────────────────────
            _LastSyncedRow(lastSyncedAt: overview.lastSyncedAt),
          ],
        ),
      ),
    );
  }
}

// ── Last synced row ───────────────────────────────────────────────────────────

class _LastSyncedRow extends StatelessWidget {
  const _LastSyncedRow({required this.lastSyncedAt});
  final DateTime? lastSyncedAt;

  @override
  Widget build(BuildContext context) {
    final label = lastSyncedAt == null
        ? 'Not yet synced for offline'
        : 'Last synced ${_formatTime(lastSyncedAt!)}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.sync_outlined,
          size: 13,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
