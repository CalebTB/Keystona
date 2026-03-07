import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../models/property.dart';
import '../providers/home_profile_provider.dart';
import '../widgets/home_profile_empty_state.dart';
import '../widgets/home_profile_skeleton.dart';

/// Home Profile overview screen — lives at [AppRoutes.home].
///
/// Shows:
///   • Property summary card (address, type, year built, sq ft, cover photo)
///   • Systems section row with count + "X nearing end of life" warning
///   • Appliances section row with count
///
/// Adaptive layout:
///   iOS  → CupertinoPageScaffold + CupertinoSliverNavigationBar (large title)
///   Android → Scaffold + SliverAppBar
class HomeProfileScreen extends ConsumerWidget {
  const HomeProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return isIOS
        ? const _IOSLayout()
        : const _AndroidLayout();
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
          const CupertinoSliverNavigationBar(largeTitle: Text('Home Profile')),
          CupertinoSliverRefreshControl(
            onRefresh: () =>
                ref.read(homeProfileProvider.notifier).refresh(),
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
        onRefresh: () => ref.read(homeProfileProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text('Home Profile', style: AppTextStyles.h3),
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
    final overviewAsync = ref.watch(homeProfileProvider);

    return overviewAsync.when(
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: HomeProfileSkeleton(),
      ),
      error: (error, _) {
        // Special-case: no property → show empty state instead of error.
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
        padding: AppPadding.screen,
        sliver: SliverList.list(
          children: [
            _PropertyCard(property: overview.property),
            const SizedBox(height: AppSizes.md),
            _SectionRow(
              icon: Icons.settings_outlined,
              label: 'Systems',
              count: overview.systemCount,
              warning: overview.systemsNearingEndOfLife > 0
                  ? '${overview.systemsNearingEndOfLife} nearing end of life'
                  : null,
              onTap: () => context.push(AppRoutes.homeSystems),
            ),
            const SizedBox(height: AppSizes.sm),
            _SectionRow(
              icon: Icons.kitchen_outlined,
              label: 'Appliances',
              count: overview.applianceCount,
              onTap: () => context.push(AppRoutes.homeAppliances),
            ),
            const SizedBox(height: AppSizes.sm),
            _SectionRow(
              icon: Icons.timeline_outlined,
              label: 'Lifespan Tracker',
              count: null,
              onTap: () => context.push(AppRoutes.homeLifespan),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Property card ─────────────────────────────────────────────────────────────

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.property});
  final Property property;

  String get _address {
    final parts = [
      property.addressLine1,
      if (property.addressLine2 != null) property.addressLine2!,
    ];
    return parts.join(', ');
  }

  String get _cityLine =>
      '${property.city}, ${property.state} ${property.zipCode}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: photo thumbnail + address.
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover photo or placeholder.
                _CoverPhoto(photoPath: property.exteriorPhotoPath),
                const SizedBox(width: AppSizes.md),
                // Address + type.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _address,
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _cityLine,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Text(
                        property.propertyType.propertyTypeLabel,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Edit icon.
                GestureDetector(
                  onTap: () => context.push(AppRoutes.homeEdit),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Stats row: year built / sq ft / bedrooms / bathrooms.
          if (_hasStats)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppSizes.radiusMd),
                  bottomRight: Radius.circular(AppSizes.radiusMd),
                ),
                color: AppColors.surfaceVariant,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              child: Row(
                children: [
                  if (property.yearBuilt != null) ...[
                    _StatChip(
                      label: 'Built ${property.yearBuilt}',
                      icon: Icons.calendar_today_outlined,
                    ),
                    const SizedBox(width: AppSizes.md),
                  ],
                  if (property.squareFeet != null) ...[
                    _StatChip(
                      label: '${_formatSqFt(property.squareFeet!)} sq ft',
                      icon: Icons.square_foot_outlined,
                    ),
                    const SizedBox(width: AppSizes.md),
                  ],
                  if (property.bedrooms != null)
                    _StatChip(
                      label:
                          '${_formatNum(property.bedrooms!)} bd / ${_formatNum(property.bathrooms ?? 0)} ba',
                      icon: Icons.bed_outlined,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool get _hasStats =>
      property.yearBuilt != null ||
      property.squareFeet != null ||
      property.bedrooms != null;

  String _formatSqFt(int sqft) {
    if (sqft >= 1000) {
      return '${(sqft / 1000).toStringAsFixed(sqft % 1000 == 0 ? 0 : 1)}k';
    }
    return sqft.toString();
  }

  String _formatNum(double n) =>
      n == n.truncateToDouble() ? n.toInt().toString() : n.toString();
}

class _CoverPhoto extends StatelessWidget {
  const _CoverPhoto({required this.photoPath});
  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: photoPath == null
          ? Icon(Icons.home, size: 36, color: AppColors.deepNavy.withValues(alpha: 0.4))
          : ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              child: const Icon(Icons.home, size: 36), // replaced when photo exists
            ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── Section row ───────────────────────────────────────────────────────────────

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
    this.warning,
  });

  final IconData icon;
  final String label;
  final int? count;
  final String? warning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.deepNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.deepNavy),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (count != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(
                      '$count',
                      style: AppTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                const SizedBox(width: AppSizes.sm),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            if (warning != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const SizedBox(width: 36 + AppSizes.md),
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 13,
                    color: AppColors.healthFair,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    warning!,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.healthFair,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
