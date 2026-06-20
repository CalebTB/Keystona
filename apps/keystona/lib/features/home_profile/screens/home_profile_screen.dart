// ignore_for_file: avoid_redundant_argument_values
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/trial_banner.dart';
import '../../../services/providers/service_providers.dart';
import '../models/appliance.dart';
import '../models/property.dart';
import '../models/system.dart';
import '../providers/appliances_provider.dart';
import '../providers/home_profile_provider.dart';
import '../providers/systems_provider.dart';
import '../widgets/home_profile_empty_state.dart';
import '../widgets/home_profile_skeleton.dart';

// ── Card decoration constant ──────────────────────────────────────────────────

const BoxDecoration _kCardDecoration = BoxDecoration(
  color: AppColors.cardBackground,
  borderRadius: BorderRadius.all(Radius.circular(AppSizes.radiusCard)),
  border: Border.fromBorderSide(
    BorderSide(color: AppColors.border, width: 1.5),
  ),
  boxShadow: [
    BoxShadow(
      color: AppColors.shadowSm,
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ],
);

// ── Lifespan helpers ──────────────────────────────────────────────────────────

double _systemAgePct(HomeSystem s) {
  if (s.installationDate == null) return 0;
  final ageYears =
      DateTime.now().difference(DateTime.parse(s.installationDate!)).inDays /
          365.25;
  final minL = s.expectedLifespanMin ?? 0;
  final maxL = s.expectedLifespanMax ?? 0;
  final avgLifespan =
      s.lifespanOverride?.toDouble() ?? ((minL + maxL) / 2.0);
  if (avgLifespan <= 0) return 0;
  return ageYears / avgLifespan;
}

double _applianceAgePct(Appliance a) {
  if (a.purchaseDate == null) return 0;
  final ageYears =
      DateTime.now().difference(DateTime.parse(a.purchaseDate!)).inDays /
          365.25;
  final avgLifespan = a.lifespanOverride?.toDouble() ??
      _applianceDefaultLifespan(a.category);
  if (avgLifespan <= 0) return 0;
  return ageYears / avgLifespan;
}

double _applianceDefaultLifespan(ApplianceCategory cat) => switch (cat) {
      ApplianceCategory.kitchen => 12.5,
      ApplianceCategory.laundry => 11.5,
      ApplianceCategory.climate => 12.5,
      ApplianceCategory.cleaning => 7.5,
      ApplianceCategory.outdoor => 10.0,
      ApplianceCategory.bathroom => 15.0,
      ApplianceCategory.other => 10.0,
    };

// ── Health status helpers ─────────────────────────────────────────────────────

String _healthLabel(double pct) {
  if (pct >= 1.0) return 'END OF LIFE';
  if (pct >= 0.75) return 'AGING';
  return 'HEALTHY';
}

Color _healthColor(double pct) {
  if (pct >= 1.0) return AppColors.accent;
  if (pct >= 0.75) return AppColors.sand;
  return AppColors.olive;
}

Color _barColor(double pct) {
  if (pct >= 1.0) return AppColors.accent;
  if (pct >= 0.75) return AppColors.sand;
  return AppColors.olive;
}

Color _healthBgColor(double pct) {
  if (pct >= 1.0) return AppColors.accentDim;
  if (pct >= 0.75) return AppColors.sandDim;
  return AppColors.oliveDim;
}

// ── Category style helpers ────────────────────────────────────────────────────

({Color bg, Color fg, IconData icon}) _systemCategoryStyle(
        SystemCategory cat) =>
    switch (cat) {
      SystemCategory.hvac => (
          bg: AppColors.slateDim,
          fg: AppColors.slate,
          icon: Icons.air_outlined
        ),
      SystemCategory.plumbing => (
          bg: AppColors.tealDim,
          fg: AppColors.teal,
          icon: Icons.water_drop_outlined
        ),
      SystemCategory.electrical => (
          bg: AppColors.sandDim,
          fg: AppColors.sand,
          icon: Icons.bolt_outlined
        ),
      SystemCategory.roofing => (
          bg: AppColors.accentDim,
          fg: AppColors.accent,
          icon: Icons.roofing_outlined
        ),
      SystemCategory.foundation => (
          bg: AppColors.slateDim,
          fg: AppColors.slate,
          icon: Icons.foundation_outlined
        ),
      SystemCategory.siding => (
          bg: AppColors.oliveDim,
          fg: AppColors.olive,
          icon: Icons.home_work_outlined
        ),
      SystemCategory.windowsDoors => (
          bg: AppColors.plumDim,
          fg: AppColors.plum,
          icon: Icons.window_outlined
        ),
      SystemCategory.insulation => (
          bg: AppColors.sandDim,
          fg: AppColors.sand,
          icon: Icons.thermostat_outlined
        ),
      SystemCategory.garage => (
          bg: AppColors.slateDim,
          fg: AppColors.slate,
          icon: Icons.garage_outlined
        ),
      SystemCategory.other => (
          bg: AppColors.warmFill,
          fg: AppColors.textSecondary,
          icon: Icons.build_outlined
        ),
    };

({Color bg, Color fg, IconData icon}) _applianceCategoryStyle(
        ApplianceCategory cat) =>
    switch (cat) {
      ApplianceCategory.kitchen => (
          bg: AppColors.plumDim,
          fg: AppColors.plum,
          icon: Icons.kitchen_outlined
        ),
      ApplianceCategory.laundry => (
          bg: AppColors.tealDim,
          fg: AppColors.teal,
          icon: Icons.local_laundry_service_outlined
        ),
      ApplianceCategory.climate => (
          bg: AppColors.slateDim,
          fg: AppColors.slate,
          icon: Icons.ac_unit_outlined
        ),
      ApplianceCategory.cleaning => (
          bg: AppColors.oliveDim,
          fg: AppColors.olive,
          icon: Icons.cleaning_services_outlined
        ),
      ApplianceCategory.outdoor => (
          bg: AppColors.oliveDim,
          fg: AppColors.olive,
          icon: Icons.yard_outlined
        ),
      ApplianceCategory.bathroom => (
          bg: AppColors.tealDim,
          fg: AppColors.teal,
          icon: Icons.bathtub_outlined
        ),
      ApplianceCategory.other => (
          bg: AppColors.warmFill,
          fg: AppColors.textSecondary,
          icon: Icons.devices_other_outlined
        ),
    };

// ── Warranty badge helper ─────────────────────────────────────────────────────

// Returns null when no badge should be shown.
({String label, Color text, Color bg})? _warrantyBadge(
    String? warrantyExpiration) {
  if (warrantyExpiration == null) return null;
  final expiry = DateTime.tryParse(warrantyExpiration);
  if (expiry == null) return null;
  if (expiry.isBefore(DateTime.now())) {
    return (
      label: 'WARRANTY EXPIRED',
      text: AppColors.accent,
      bg: AppColors.accentDim,
    );
  }
  return (
    label: 'WARRANTY ${expiry.year}',
    text: AppColors.olive,
    bg: AppColors.oliveDim,
  );
}

// ── Currency formatter ────────────────────────────────────────────────────────

String _fmtCost(double cost) {
  if (cost >= 1000) {
    final k = cost / 1000;
    return k == k.truncateToDouble()
        ? '~\$${k.toInt()}k'
        : '~\$${k.toStringAsFixed(1)}k';
  }
  final fmt = NumberFormat('#,###', 'en_US');
  return '~\$${fmt.format(cost.round())}';
}

// ── Main screen ───────────────────────────────────────────────────────────────

/// Home Profile overview screen — your home's medical record.
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
      child: Stack(
        children: [
          CustomScrollView(
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
                onRefresh: () async {
                  ref.invalidate(homeProfileProvider);
                  ref.invalidate(systemsProvider);
                  ref.invalidate(appliancesProvider);
                },
              ),
              const _ContentSliver(),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          // iOS FAB — Stack+Positioned pattern (CupertinoPageScaffold has no
          // floatingActionButton slot).
          Positioned(
            bottom: 110,
            right: 22,
            child: _AddFab(
              onPressed: () => _showAddSheet(context),
            ),
          ),
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
        onPressed: () => _showAddSheet(context),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: AppColors.textInverse),
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async {
          ref.invalidate(homeProfileProvider);
          ref.invalidate(systemsProvider);
          ref.invalidate(appliancesProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title:
                  Text('Home Profile', style: AppTextStyles.displayMedium),
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
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
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
            onRetry: () =>
                ref.read(homeProfileProvider.notifier).refresh(),
          ),
        );
      },
      data: (overview) => SliverPadding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenPadding),
        sliver: SliverList.list(
          children: [
            const TrialBanner(),
            // 1. Dark hero property card.
            _PropertyCard(
              property: overview.property,
              exteriorPhotoUrl: overview.exteriorPhotoSignedUrl,
            ),
            const SizedBox(height: AppSizes.md),

            // 2. 5-year replacement forecast strip (conditional).
            _ForecastStrip(),
            // SizedBox is rendered inside _ForecastStrip when content exists.

            // 3. Systems section.
            _SystemsSection(),
            const SizedBox(height: AppSizes.lg),

            // 4. Appliances section.
            _AppliancesSection(),
            const SizedBox(height: AppSizes.md),

          ],
        ),
      ),
    );
  }
}

// ── 1. Property card — dark hero block ───────────────────────────────────────

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.property, this.exteriorPhotoUrl});
  final Property property;
  final String? exteriorPhotoUrl;

  String get _streetLine => [
        property.addressLine1,
        if (property.addressLine2 != null) property.addressLine2!,
      ].join(', ');

  String get _cityLine =>
      '${property.city}, ${property.state} ${property.zipCode}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius:
            BorderRadius.all(Radius.circular(AppSizes.radiusLg + 2)), // 18px
      ),
      padding: const EdgeInsets.all(AppSizes.md + 4), // 20px
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exterior photo thumbnail (or placeholder).
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(14)),
                child: Container(
                  width: 64,
                  height: 64,
                  color: AppColors.darkBorder,
                  child: exteriorPhotoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: exteriorPhotoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.darkTextSecondary,
                            ),
                          ),
                          errorWidget: (_, _, _) => const Icon(
                            Icons.home_outlined,
                            size: 28,
                            color: AppColors.darkTextSecondary,
                          ),
                        )
                      : const Icon(
                          Icons.home_outlined,
                          size: 28,
                          color: AppColors.darkTextSecondary,
                        ),
                ),
              ),
              const SizedBox(width: 14),
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
                  decoration: const BoxDecoration(
                    color: AppColors.darkBorder,
                    borderRadius: BorderRadius.all(
                        Radius.circular(AppSizes.radiusFull)),
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
          _StatCell(
              value: '${property.yearBuilt}', label: 'Year Built'),
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
          style:
              AppTextStyles.monoDisplay.copyWith(color: AppColors.darkText),
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

// ── 2. 5-year forecast strip ──────────────────────────────────────────────────

class _ForecastStrip extends ConsumerWidget {
  const _ForecastStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemsAsync = ref.watch(systemsProvider);
    return systemsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (systems) {
        final now = DateTime.now();
        final forecastSystems = systems.where((s) {
          if (s.installationDate == null) return false;
          final minL = s.expectedLifespanMin ?? 0;
          final maxL = s.expectedLifespanMax ?? 0;
          final avg = s.lifespanOverride?.toDouble() ??
              ((minL + maxL) / 2.0);
          if (avg <= 0) return false;
          final ageYrs =
              now.difference(DateTime.parse(s.installationDate!)).inDays /
                  365.25;
          final replaceYear =
              now.year + (avg - ageYrs).ceil();
          return replaceYear <= now.year + 5;
        }).toList();

        if (forecastSystems.isEmpty) return const SizedBox.shrink();

        final totalCost = forecastSystems
            .map((s) => s.estimatedReplacementCost ?? 0.0)
            .fold(0.0, (a, b) => a + b);

        final costStr =
            totalCost > 0 ? _fmtCost(totalCost) : null;

        return Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.sandDim,
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusCard),
                border: Border.all(
                  color: AppColors.sand.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.sand.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.schedule_outlined,
                      size: 18,
                      color: AppColors.sand,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '5-Year Replacement Forecast',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.sand,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${forecastSystems.length} system${forecastSystems.length == 1 ? '' : 's'} due for replacement'
                          '${costStr != null ? ' · $costStr total' : ''}',
                          style: AppTextStyles.monoLabel.copyWith(
                            color: AppColors.sand.withValues(alpha: 0.8),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.sand.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),
          ],
        );
      },
    );
  }
}

// ── 3. Systems section ────────────────────────────────────────────────────────

class _SystemsSection extends ConsumerWidget {
  const _SystemsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemsAsync = ref.watch(systemsProvider);
    return systemsAsync.when(
      loading: () => const _SectionLoadingPlaceholder(label: 'Systems'),
      error: (_, _) => const SizedBox.shrink(),
      data: (systems) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(label: 'Systems', count: systems.length),
          const SizedBox(height: 8),
          const _StatusLegend(),
          const SizedBox(height: 10),
          if (systems.isEmpty)
            _EmptySectionHint(
              label: 'No systems tracked yet',
              onTap: () => context.push(AppRoutes.homeSystemsAdd),
            )
          else
            ...systems.map((s) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppSizes.cardGap),
                  child: _SystemCard(system: s),
                )),
        ],
      ),
    );
  }
}

// ── 4. Appliances section ─────────────────────────────────────────────────────

class _AppliancesSection extends ConsumerWidget {
  const _AppliancesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appliancesAsync = ref.watch(appliancesProvider);
    return appliancesAsync.when(
      loading: () =>
          const _SectionLoadingPlaceholder(label: 'Appliances'),
      error: (_, _) => const SizedBox.shrink(),
      data: (appliances) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(label: 'Appliances', count: appliances.length),
          const SizedBox(height: 10),
          if (appliances.isEmpty)
            _EmptySectionHint(
              label: 'No appliances tracked yet',
              onTap: () => context.push(AppRoutes.homeAppliancesAdd),
            )
          else
            ...appliances.map((a) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppSizes.cardGap),
                  child: _ApplianceCard(appliance: a),
                )),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.fraunces(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Text(
          '$count tracked',
          style: AppTextStyles.monoLabel.copyWith(
            color: AppColors.textTertiary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ── Status legend ─────────────────────────────────────────────────────────────

class _StatusLegend extends StatelessWidget {
  const _StatusLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _LegendDot(color: AppColors.olive, label: 'Healthy'),
        SizedBox(width: 14),
        _LegendDot(color: AppColors.sand, label: 'Aging'),
        SizedBox(width: 14),
        _LegendDot(color: AppColors.accent, label: 'End of Life'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── System card ───────────────────────────────────────────────────────────────

class _SystemCard extends StatelessWidget {
  const _SystemCard({required this.system});
  final HomeSystem system;

  @override
  Widget build(BuildContext context) {
    final pct = _systemAgePct(system);
    final style = _systemCategoryStyle(system.category);
    final badge = _warrantyBadge(system.warrantyExpiration);
    final healthLbl = _healthLabel(pct);
    final healthColor = _healthColor(pct);
    final healthBg = _healthBgColor(pct);
    final barColor = _barColor(pct);
    final barValue = pct.clamp(0.0, 1.0);

    String? ageText;
    String? remainingText;
    Color remainingColor = AppColors.textTertiary;

    if (system.installationDate != null) {
      final ageYears =
          DateTime.now()
                  .difference(DateTime.parse(system.installationDate!))
                  .inDays /
              365.25;
      final dt = DateTime.parse(system.installationDate!);
      final month = DateFormat('MMM').format(dt);
      ageText =
          'Installed $month ${dt.year} · ${ageYears.toStringAsFixed(1)} yrs';

      final minL = system.expectedLifespanMin ?? 0;
      final maxL = system.expectedLifespanMax ?? 0;
      final avg =
          system.lifespanOverride?.toDouble() ?? ((minL + maxL) / 2.0);
      if (avg > 0) {
        if (pct >= 1.0) {
          remainingText = 'Past expected';
          remainingColor = AppColors.accent;
        } else {
          final remaining = avg - ageYears;
          if (remaining < 1) {
            remainingText = '< 1 yr left';
            remainingColor = AppColors.sand;
          } else {
            final lo = math.max(0, remaining.floor());
            final hi = remaining.ceil();
            remainingText = '$lo–$hi yr left';
            remainingColor = healthColor;
          }
        }
      }
    }

    final specParts = [
      if (system.brand != null) system.brand!,
      if (system.modelNumber != null) system.modelNumber!,
      if (system.location != null) system.location!,
    ];

    return GestureDetector(
      onTap: () => context.push(
        AppRoutes.homeSystemDetail.replaceFirst(':systemId', system.id),
        extra: system,
      ),
      child: Container(
        decoration: _kCardDecoration,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row: icon + name + health badge.
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: style.bg,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(style.icon, size: 20, color: style.fg),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              system.name,
                              style: AppTextStyles.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Health badge.
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: healthBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              healthLbl,
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: healthColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (system.category.label.isNotEmpty)
                        Text(
                          system.category.label,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Brand · model · location row.
            if (specParts.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                specParts.join(' · '),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textTertiary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Lifespan bar.
            if (system.installationDate != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: barValue,
                  minHeight: 5,
                  backgroundColor: AppColors.warmInset,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
              const SizedBox(height: 5),
              // Age row.
              Row(
                children: [
                  if (ageText != null)
                    Text(
                      ageText,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  const Spacer(),
                  if (remainingText != null)
                    Text(
                      remainingText,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: remainingColor,
                      ),
                    ),
                ],
              ),
            ],

            // Divider.
            const SizedBox(height: 8),
            const Divider(color: AppColors.warmFill, height: 1),
            const SizedBox(height: 8),

            // Cost tag + warranty badge row.
            Row(
              children: [
                if (system.estimatedReplacementCost != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.attach_money,
                        size: 12,
                        color: AppColors.textTertiary,
                      ),
                      Text(
                        '${_fmtCost(system.estimatedReplacementCost!)} replacement',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                const Spacer(),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badge.bg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge.label,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: badge.text,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Appliance card ────────────────────────────────────────────────────────────

class _ApplianceCard extends StatelessWidget {
  const _ApplianceCard({required this.appliance});
  final Appliance appliance;

  @override
  Widget build(BuildContext context) {
    final pct = _applianceAgePct(appliance);
    final style = _applianceCategoryStyle(appliance.category);
    final badge = _warrantyBadge(appliance.warrantyExpiration);
    final healthLbl = _healthLabel(pct);
    final healthColor = _healthColor(pct);
    final healthBg = _healthBgColor(pct);
    final barColor = _barColor(pct);
    final barValue = pct.clamp(0.0, 1.0);

    String? ageText;
    String? remainingText;
    Color remainingColor = AppColors.textTertiary;

    if (appliance.purchaseDate != null) {
      final ageYears =
          DateTime.now()
                  .difference(DateTime.parse(appliance.purchaseDate!))
                  .inDays /
              365.25;
      final dt = DateTime.parse(appliance.purchaseDate!);
      final month = DateFormat('MMM').format(dt);
      ageText =
          'Purchased $month ${dt.year} · ${ageYears.toStringAsFixed(1)} yrs';

      final avg = appliance.lifespanOverride?.toDouble() ??
          _applianceDefaultLifespan(appliance.category);
      if (avg > 0) {
        if (pct >= 1.0) {
          remainingText = 'Past expected';
          remainingColor = AppColors.accent;
        } else {
          final remaining = avg - ageYears;
          if (remaining < 1) {
            remainingText = '< 1 yr left';
            remainingColor = AppColors.sand;
          } else {
            final lo = math.max(0, remaining.floor());
            final hi = remaining.ceil();
            remainingText = '$lo–$hi yr left';
            remainingColor = healthColor;
          }
        }
      }
    }

    final specParts = [
      if (appliance.brand != null) appliance.brand!,
      if (appliance.modelNumber != null) appliance.modelNumber!,
      if (appliance.location != null) appliance.location!,
    ];

    return GestureDetector(
      onTap: () => context.push(
        AppRoutes.homeApplianceDetail.replaceFirst(
            ':applianceId', appliance.id),
        extra: appliance,
      ),
      child: Container(
        decoration: _kCardDecoration,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row: icon + name + health badge.
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: style.bg,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(style.icon, size: 20, color: style.fg),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              appliance.name,
                              style: AppTextStyles.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Health badge.
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: healthBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              healthLbl,
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: healthColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        appliance.category.label,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Brand · model · location row.
            if (specParts.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                specParts.join(' · '),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textTertiary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Lifespan bar.
            if (appliance.purchaseDate != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: barValue,
                  minHeight: 5,
                  backgroundColor: AppColors.warmInset,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  if (ageText != null)
                    Text(
                      ageText,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  const Spacer(),
                  if (remainingText != null)
                    Text(
                      remainingText,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: remainingColor,
                      ),
                    ),
                ],
              ),
            ],

            // Divider.
            const SizedBox(height: 8),
            const Divider(color: AppColors.warmFill, height: 1),
            const SizedBox(height: 8),

            // Cost tag + warranty badge row.
            Row(
              children: [
                if (appliance.estimatedReplacementCost != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.attach_money,
                        size: 12,
                        color: AppColors.textTertiary,
                      ),
                      Text(
                        '${_fmtCost(appliance.estimatedReplacementCost!)} purchased',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                const Spacer(),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badge.bg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge.label,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: badge.text,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


// ── Add choice sheet ──────────────────────────────────────────────────────────

void _showAddSheet(BuildContext context) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => CupertinoActionSheet(
      title: const Text('Add to Home Profile'),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            context.push(AppRoutes.homeSystemsAdd);
          },
          child: const Text('Add System'),
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            context.push(AppRoutes.homeAppliancesAdd);
          },
          child: const Text('Add Appliance'),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () =>
            Navigator.of(context, rootNavigator: true).pop(),
        child: const Text('Cancel'),
      ),
    ),
  );
}

// ── FAB ───────────────────────────────────────────────────────────────────────

class _AddFab extends StatelessWidget {
  const _AddFab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: AppColors.accent,
      child: const Icon(Icons.add, color: AppColors.textInverse),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SectionLoadingPlaceholder extends StatelessWidget {
  const _SectionLoadingPlaceholder({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.fraunces(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 80,
          decoration: _kCardDecoration,
        ),
      ],
    );
  }
}

class _EmptySectionHint extends StatelessWidget {
  const _EmptySectionHint({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.warmFill,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle_outline,
              size: 16,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
