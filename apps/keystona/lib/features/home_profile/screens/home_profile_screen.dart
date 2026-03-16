import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/trial_banner.dart';
import '../../../services/providers/service_providers.dart';
import '../models/property.dart';
import '../providers/home_profile_provider.dart';
import '../widgets/home_profile_empty_state.dart';
import '../widgets/home_profile_skeleton.dart';

/// Home Profile overview screen — lives at [AppRoutes.home].
///
/// Adaptive layout:
///   iOS  → CupertinoPageScaffold + CupertinoSliverNavigationBar (large title)
///   Android → Scaffold + SliverAppBar
class HomeProfileScreen extends ConsumerWidget {
  const HomeProfileScreen({super.key});

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
      backgroundColor: AppColors.warmOffWhite,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(
              'Home Profile',
              style: AppTextStyles.displayMedium,
            ),
            backgroundColor: AppColors.warmOffWhite,
            border: null,
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => ref.read(authServiceProvider).signOut(),
              child: Text(
                'Sign Out',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
          CupertinoSliverRefreshControl(
            onRefresh: () =>
                ref.read(homeProfileProvider.notifier).refresh(),
          ),
          const _ContentSliver(),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
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
        color: AppColors.accent,
        onRefresh: () => ref.read(homeProfileProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text('Home Profile', style: AppTextStyles.displayMedium),
              floating: true,
              backgroundColor: AppColors.warmOffWhite,
              scrolledUnderElevation: 0,
              elevation: 0,
              actions: [
                TextButton(
                  onPressed: () => ref.read(authServiceProvider).signOut(),
                  child: Text(
                    'Sign Out',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.accent),
                  ),
                ),
              ],
            ),
            const _ContentSliver(),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
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
    final overviewAsync = ref.watch(homeProfileProvider);

    return overviewAsync.when(
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: HomeProfileSkeleton(),
      ),
      error: (error, _) {
        if (error is NoPropertyException) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: HomeProfileEmptyState(
              onSetup: () => context.push(AppRoutes.onboarding),
            ),
          );
        }
        return SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorView(
            message: "Couldn't load your home profile.",
            onRetry: () => ref.read(homeProfileProvider.notifier).refresh(),
          ),
        );
      },
      data: (overview) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
        sliver: SliverList.list(
          children: [
            const TrialBanner(),
            // Dark hero property card.
            _PropertyCard(property: overview.property),
            const SizedBox(height: AppSizes.md),

            // ── Systems section ──────────────────────────────────────────
            _SectionHeader(
              label: 'Systems',
              count: overview.systemCount,
              warning: overview.systemsNearingEndOfLife > 0
                  ? '${overview.systemsNearingEndOfLife} nearing end of life'
                  : null,
            ),
            const SizedBox(height: 10),
            _SectionTile(
              iconBackground: AppColors.slateDim,
              iconColor: AppColors.slate,
              icon: Icons.settings_outlined,
              label: 'Systems',
              count: overview.systemCount,
              onTap: () => context.push(AppRoutes.homeSystems),
            ),
            const SizedBox(height: AppSizes.cardGap),
            _SectionTile(
              iconBackground: AppColors.oliveDim,
              iconColor: AppColors.olive,
              icon: Icons.kitchen_outlined,
              label: 'Appliances',
              count: overview.applianceCount,
              onTap: () => context.push(AppRoutes.homeAppliances),
            ),
            const SizedBox(height: AppSizes.cardGap),
            _SectionTile(
              iconBackground: AppColors.sandDim,
              iconColor: AppColors.sand,
              icon: Icons.timeline_outlined,
              label: 'Lifespan Tracker',
              count: null,
              onTap: () => context.push(AppRoutes.homeLifespan),
            ),
            const SizedBox(height: AppSizes.md),

            // ── Emergency Hub ────────────────────────────────────────────
            _EmergencyHubTile(
              onTap: () => context.push(AppRoutes.emergency),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Property card — dark hero block ──────────────────────────────────────────

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.property});
  final Property property;

  String get _streetLine => [
        property.addressLine1,
        if (property.addressLine2 != null) property.addressLine2!,
      ].join(', ');

  String get _cityLine =>
      '${property.city}, ${property.state} ${property.zipCode}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg + 2), // 18px
      ),
      padding: const EdgeInsets.all(AppSizes.md + 4), // 20px
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo + address row.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail.
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.darkBorder,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: const Icon(
                  Icons.home_outlined,
                  size: 28,
                  color: AppColors.darkTextSecondary,
                ),
              ),
              const SizedBox(width: 14),
              // Address.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _streetLine,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.darkText,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _cityLine,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.darkTextTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Edit button.
              GestureDetector(
                onTap: () => context.push(AppRoutes.homeEdit),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.darkBorder,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 15,
                    color: AppColors.darkTextSecondary,
                  ),
                ),
              ),
            ],
          ),

          // Stats row.
          if (_hasStats) ...[
            const SizedBox(height: 16),
            _PropertyStats(property: property),
          ],
        ],
      ),
    );
  }

  bool get _hasStats =>
      property.yearBuilt != null ||
      property.squareFeet != null ||
      property.bedrooms != null;
}

class _PropertyStats extends StatelessWidget {
  const _PropertyStats({required this.property});
  final Property property;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (property.yearBuilt != null) ...[
          _StatCell(value: '${property.yearBuilt}', label: 'Year Built'),
          const SizedBox(width: 20),
        ],
        if (property.squareFeet != null) ...[
          _StatCell(
            value: _fmtSqFt(property.squareFeet!),
            label: 'Sq Ft',
          ),
          const SizedBox(width: 20),
        ],
        if (property.bedrooms != null)
          _StatCell(
            value: '${_fmtNum(property.bedrooms!)}/'
                '${_fmtNum(property.bathrooms ?? 0)}',
            label: 'Bed/Bath',
          ),
      ],
    );
  }

  static String _fmtSqFt(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      return k == k.truncateToDouble()
          ? '${k.toInt()}k'
          : '${k.toStringAsFixed(1)}k';
    }
    return '$n';
  }

  static String _fmtNum(double n) =>
      n == n.truncateToDouble() ? n.toInt().toString() : '$n';
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTextStyles.monoDisplay.copyWith(color: AppColors.darkText),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: AppTextStyles.monoTiny.copyWith(
            color: AppColors.darkTextTertiary,
          ),
        ),
      ],
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.count,
    this.warning,
  });

  final String label;
  final int count;
  final String? warning;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: AppTextStyles.headlineMedium),
        const SizedBox(width: AppSizes.sm),
        Text(
          '$count tracked',
          style: AppTextStyles.monoLabel.copyWith(color: AppColors.textTertiary),
        ),
        if (warning != null) ...[
          const Spacer(),
          Icon(Icons.warning_amber_rounded,
              size: 12, color: AppColors.sand),
          const SizedBox(width: 3),
          Text(
            warning!,
            style: AppTextStyles.monoLabel
                .copyWith(color: AppColors.sand, fontSize: 10),
          ),
        ],
      ],
    );
  }
}

// ── Section tile ──────────────────────────────────────────────────────────────

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.iconBackground,
    required this.iconColor,
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final Color iconBackground;
  final Color iconColor;
  final IconData icon;
  final String label;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D2A2420),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        child: Row(
          children: [
            // Category icon.
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm + 1),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            // Label.
            Expanded(
              child: Text(label, style: AppTextStyles.titleSmall),
            ),
            // Count badge.
            if (count != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warmFill,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  '$count',
                  style: AppTextStyles.monoLabel.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
            ],
            Icon(Icons.chevron_right,
                size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ── Emergency Hub tile ────────────────────────────────────────────────────────

class _EmergencyHubTile extends StatelessWidget {
  const _EmergencyHubTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.accentDim,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.18),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D2A2420),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm + 1),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 20,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Emergency Hub',
                style: AppTextStyles.titleSmall.copyWith(color: AppColors.accent),
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}
