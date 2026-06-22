// ignore_for_file: avoid_redundant_argument_values
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_shadows.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';

import '../../../core/router/app_router.dart';



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
  color: AuroraColors.paper,
  borderRadius: AuroraRadius.lg,
  border: Border.fromBorderSide(
    BorderSide(color: AuroraColors.inkBorder, width: 1.5),
  ),
  boxShadow: AuroraShadows.card,
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
  if (pct >= 1.0) return AuroraColors.coral;
  if (pct >= 0.75) return AuroraColors.yellow;
  return AuroraColors.lime;
}

Color _barColor(double pct) {
  if (pct >= 1.0) return AuroraColors.coral;
  if (pct >= 0.75) return AuroraColors.yellow;
  return AuroraColors.lime;
}

Color _healthBgColor(double pct) {
  if (pct >= 1.0) return AuroraColors.coralDim;
  if (pct >= 0.75) return AuroraColors.yellowDim;
  return AuroraColors.limeDim;
}

// ── Category style helpers ────────────────────────────────────────────────────

({Color bg, Color fg, IconData icon}) _systemCategoryStyle(
        SystemCategory cat) =>
    switch (cat) {
      SystemCategory.hvac => (
          bg: AuroraColors.cobaltDim,
          fg: AuroraColors.cobalt,
          icon: Icons.air_outlined
        ),
      SystemCategory.plumbing => (
          bg: AuroraColors.cobaltDim,
          fg: AuroraColors.cobalt,
          icon: Icons.water_drop_outlined
        ),
      SystemCategory.electrical => (
          bg: AuroraColors.yellowDim,
          fg: AuroraColors.yellow,
          icon: Icons.bolt_outlined
        ),
      SystemCategory.roofing => (
          bg: AuroraColors.coralDim,
          fg: AuroraColors.coral,
          icon: Icons.roofing_outlined
        ),
      SystemCategory.foundation => (
          bg: AuroraColors.cobaltDim,
          fg: AuroraColors.cobalt,
          icon: Icons.foundation_outlined
        ),
      SystemCategory.siding => (
          bg: AuroraColors.limeDim,
          fg: AuroraColors.lime,
          icon: Icons.home_work_outlined
        ),
      SystemCategory.windowsDoors => (
          bg: AuroraColors.cobaltDim,
          fg: AuroraColors.cobalt,
          icon: Icons.window_outlined
        ),
      SystemCategory.insulation => (
          bg: AuroraColors.yellowDim,
          fg: AuroraColors.yellow,
          icon: Icons.thermostat_outlined
        ),
      SystemCategory.garage => (
          bg: AuroraColors.cobaltDim,
          fg: AuroraColors.cobalt,
          icon: Icons.garage_outlined
        ),
      SystemCategory.other => (
          bg: AuroraColors.paper,
          fg: AuroraColors.inkSecondary,
          icon: Icons.build_outlined
        ),
    };

({Color bg, Color fg, IconData icon}) _applianceCategoryStyle(
        ApplianceCategory cat) =>
    switch (cat) {
      ApplianceCategory.kitchen => (
          bg: AuroraColors.cobaltDim,
          fg: AuroraColors.cobalt,
          icon: Icons.kitchen_outlined
        ),
      ApplianceCategory.laundry => (
          bg: AuroraColors.cobaltDim,
          fg: AuroraColors.cobalt,
          icon: Icons.local_laundry_service_outlined
        ),
      ApplianceCategory.climate => (
          bg: AuroraColors.cobaltDim,
          fg: AuroraColors.cobalt,
          icon: Icons.ac_unit_outlined
        ),
      ApplianceCategory.cleaning => (
          bg: AuroraColors.limeDim,
          fg: AuroraColors.lime,
          icon: Icons.cleaning_services_outlined
        ),
      ApplianceCategory.outdoor => (
          bg: AuroraColors.limeDim,
          fg: AuroraColors.lime,
          icon: Icons.yard_outlined
        ),
      ApplianceCategory.bathroom => (
          bg: AuroraColors.cobaltDim,
          fg: AuroraColors.cobalt,
          icon: Icons.bathtub_outlined
        ),
      ApplianceCategory.other => (
          bg: AuroraColors.paper,
          fg: AuroraColors.inkSecondary,
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
      text: AuroraColors.coral,
      bg: AuroraColors.coralDim,
    );
  }
  return (
    label: 'WARRANTY ${expiry.year}',
    text: AuroraColors.lime,
    bg: AuroraColors.limeDim,
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
      backgroundColor: AuroraColors.paper,
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: Text(
                  'Home Profile',
                  style: AuroraType.h1,
                ),
                backgroundColor: AuroraColors.paper,
                border: null,
                trailing: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => ref.read(authServiceProvider).signOut(),
                  child: Text(
                    'Sign Out',
                    style: AuroraType.label.copyWith(
                      color: AuroraColors.coral,
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
      backgroundColor: AuroraColors.paper,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        backgroundColor: AuroraColors.coral,
        child: const Icon(Icons.add, color: AuroraColors.paper),
      ),
      body: RefreshIndicator(
        color: AuroraColors.coral,
        onRefresh: () async {
          ref.invalidate(homeProfileProvider);
          ref.invalidate(systemsProvider);
          ref.invalidate(appliancesProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title:
                  Text('Home Profile', style: AuroraType.h1),
              floating: true,
              backgroundColor: AuroraColors.paper,
              scrolledUnderElevation: 0,
              elevation: 0,
              actions: [
                TextButton(
                  onPressed: () => ref.read(authServiceProvider).signOut(),
                  child: Text(
                    'Sign Out',
                    style: AuroraType.label
                        .copyWith(color: AuroraColors.coral),
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
            horizontal: AuroraSpacing.screenPadH),
        sliver: SliverList.list(
          children: [
            const TrialBanner(),
            // 1. Dark hero property card.
            _PropertyCard(
              property: overview.property,
              exteriorPhotoUrl: overview.exteriorPhotoSignedUrl,
            ),
            const SizedBox(height: AuroraSpacing.space5),

            // 2. 5-year replacement forecast strip (conditional).
            _ForecastStrip(),
            // SizedBox is rendered inside _ForecastStrip when content exists.

            // 3. Systems section.
            _SystemsSection(),
            const SizedBox(height: AuroraSpacing.space7),

            // 4. Appliances section.
            _AppliancesSection(),
            const SizedBox(height: AuroraSpacing.space5),

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
        color: AuroraColors.ink,
        borderRadius: AuroraRadius.xxl,
      ),
      padding: const EdgeInsets.all(AuroraSpacing.space5 + 4), // 20px
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exterior photo thumbnail (or placeholder).
              ClipRRect(
                borderRadius: AuroraRadius.lg,
                child: Container(
                  width: 64,
                  height: 64,
                  color: const Color(0x1AFFFFFF),
                  child: exteriorPhotoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: exteriorPhotoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AuroraColors.inkSecondary,
                            ),
                          ),
                          errorWidget: (_, _, _) => const Icon(
                            Icons.home_outlined,
                            size: 28,
                            color: AuroraColors.inkSecondary,
                          ),
                        )
                      : const Icon(
                          Icons.home_outlined,
                          size: 28,
                          color: AuroraColors.inkSecondary,
                        ),
                ),
              ),
              const SizedBox(width: AuroraSpacing.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _streetLine,
                      style: AuroraType.h1.copyWith(
                        color: AuroraColors.paper,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: AuroraSpacing.space1),
                    Text(
                      _cityLine,
                      style: AuroraType.bodySm.copyWith(
                        color: AuroraColors.paper.withValues(alpha: 0.35),
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
                    color: Color(0x1AFFFFFF),
                    borderRadius: AuroraRadius.full,
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 15,
                    color: AuroraColors.inkSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (_hasStats) ...[
            const SizedBox(height: AuroraSpacing.space4),
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
          const SizedBox(width: AuroraSpacing.space5),
        ],
        if (property.squareFeet != null) ...[
          _StatCell(
            value: _fmtSqFt(property.squareFeet!),
            label: 'Sq Ft',
          ),
          const SizedBox(width: AuroraSpacing.space5),
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
              AuroraType.number.copyWith(color: AuroraColors.paper),
        ),
        const SizedBox(height: AuroraSpacing.space1),
        Text(
          label.toUpperCase(),
          style: AuroraType.labelSm.copyWith(
            color: AuroraColors.paper.withValues(alpha: 0.35),
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
                color: AuroraColors.yellowDim,
                borderRadius: AuroraRadius.lg,
                border: Border.all(
                  color: AuroraColors.yellow.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: AuroraSpacing.space4, vertical: AuroraSpacing.space3),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AuroraColors.yellow.withValues(alpha: 0.15),
                      borderRadius: AuroraRadius.md,
                    ),
                    child: const Icon(
                      Icons.schedule_outlined,
                      size: 18,
                      color: AuroraColors.yellow,
                    ),
                  ),
                  const SizedBox(width: AuroraSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '5-Year Replacement Forecast',
                          style: AuroraType.body.copyWith(
                            color: AuroraColors.yellow,
                          ),
                        ),
                        const SizedBox(height: AuroraSpacing.space1),
                        Text(
                          '${forecastSystems.length} system${forecastSystems.length == 1 ? '' : 's'} due for replacement'
                          '${costStr != null ? ' · $costStr total' : ''}',
                          style: AuroraType.label.copyWith(
                            color: AuroraColors.yellow.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AuroraColors.yellow.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AuroraSpacing.space5),
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
          const SizedBox(height: AuroraSpacing.space2),
          const _StatusLegend(),
          const SizedBox(height: AuroraSpacing.space2),
          if (systems.isEmpty)
            _EmptySectionHint(
              label: 'No systems tracked yet',
              onTap: () => context.push(AppRoutes.homeSystemsAdd),
            )
          else
            ...systems.map((s) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: AuroraSpacing.space3),
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
          const SizedBox(height: AuroraSpacing.space2),
          if (appliances.isEmpty)
            _EmptySectionHint(
              label: 'No appliances tracked yet',
              onTap: () => context.push(AppRoutes.homeAppliancesAdd),
            )
          else
            ...appliances.map((a) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: AuroraSpacing.space3),
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
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AuroraColors.inkSecondary,
            borderRadius: AuroraRadius.xs,
          ),
        ),
        const SizedBox(width: AuroraSpacing.space2),
        Text(
          label.toUpperCase(),
          style: AuroraType.label.copyWith(color: AuroraColors.inkSecondary),
        ),
        const Spacer(),
        Text(
          '$count tracked',
          style: AuroraType.label.copyWith(
            color: AuroraColors.inkTertiary,
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
        _LegendDot(color: AuroraColors.lime, label: 'Healthy'),
        SizedBox(width: AuroraSpacing.space4),
        _LegendDot(color: AuroraColors.yellow, label: 'Aging'),
        SizedBox(width: AuroraSpacing.space4),
        _LegendDot(color: AuroraColors.coral, label: 'End of Life'),
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
        const SizedBox(width: AuroraSpacing.space1),
        Text(
          label,
          style: AuroraType.labelSm.copyWith(
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
    Color remainingColor = AuroraColors.inkTertiary;

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
          remainingColor = AuroraColors.coral;
        } else {
          final remaining = avg - ageYears;
          if (remaining < 1) {
            remainingText = '< 1 yr left';
            remainingColor = AuroraColors.yellow;
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
        padding: const EdgeInsets.all(AuroraSpacing.space4),
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
                    borderRadius: AuroraRadius.lg,
                  ),
                  child: Icon(style.icon, size: 20, color: style.fg),
                ),
                const SizedBox(width: AuroraSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              system.name,
                              style: AuroraType.h3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AuroraSpacing.space2),
                          // Health badge.
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: healthBg,
                              borderRadius: AuroraRadius.xs,
                            ),
                            child: Text(
                              healthLbl,
                              style: AuroraType.labelSm.copyWith(
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
                          style: AuroraType.bodySm.copyWith(
                            color: AuroraColors.inkTertiary,
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
              const SizedBox(height: AuroraSpacing.space2),
              Text(
                specParts.join(' · '),
                style: AuroraType.bodySm.copyWith(
                  color: AuroraColors.inkTertiary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Lifespan bar.
            if (system.installationDate != null) ...[
              const SizedBox(height: AuroraSpacing.space2),
              ClipRRect(
                borderRadius: AuroraRadius.xs,
                child: LinearProgressIndicator(
                  value: barValue,
                  minHeight: 5,
                  backgroundColor: AuroraColors.inkBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
              const SizedBox(height: AuroraSpacing.space1),
              // Age row.
              Row(
                children: [
                  if (ageText != null)
                    Text(
                      ageText,
                      style: AuroraType.labelSm.copyWith(
                        color: AuroraColors.inkTertiary,
                      ),
                    ),
                  const Spacer(),
                  if (remainingText != null)
                    Text(
                      remainingText,
                      style: AuroraType.labelSm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: remainingColor,
                      ),
                    ),
                ],
              ),
            ],

            // Divider.
            const SizedBox(height: AuroraSpacing.space2),
            const Divider(color: AuroraColors.inkBorder, height: 1, thickness: 0.5),
            const SizedBox(height: AuroraSpacing.space2),

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
                        color: AuroraColors.inkTertiary,
                      ),
                      Text(
                        '${_fmtCost(system.estimatedReplacementCost!)} replacement',
                        style: AuroraType.labelSm.copyWith(
                          color: AuroraColors.inkTertiary,
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
                      borderRadius: AuroraRadius.xs,
                    ),
                    child: Text(
                      badge.label,
                      style: AuroraType.labelSm.copyWith(
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
    Color remainingColor = AuroraColors.inkTertiary;

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
          remainingColor = AuroraColors.coral;
        } else {
          final remaining = avg - ageYears;
          if (remaining < 1) {
            remainingText = '< 1 yr left';
            remainingColor = AuroraColors.yellow;
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
        padding: const EdgeInsets.all(AuroraSpacing.space4),
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
                    borderRadius: AuroraRadius.lg,
                  ),
                  child: Icon(style.icon, size: 20, color: style.fg),
                ),
                const SizedBox(width: AuroraSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              appliance.name,
                              style: AuroraType.h3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AuroraSpacing.space2),
                          // Health badge.
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: healthBg,
                              borderRadius: AuroraRadius.xs,
                            ),
                            child: Text(
                              healthLbl,
                              style: AuroraType.labelSm.copyWith(
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
                        style: AuroraType.bodySm.copyWith(
                          color: AuroraColors.inkTertiary,
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
              const SizedBox(height: AuroraSpacing.space2),
              Text(
                specParts.join(' · '),
                style: AuroraType.bodySm.copyWith(
                  color: AuroraColors.inkTertiary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Lifespan bar.
            if (appliance.purchaseDate != null) ...[
              const SizedBox(height: AuroraSpacing.space2),
              ClipRRect(
                borderRadius: AuroraRadius.xs,
                child: LinearProgressIndicator(
                  value: barValue,
                  minHeight: 5,
                  backgroundColor: AuroraColors.inkBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
              const SizedBox(height: AuroraSpacing.space1),
              Row(
                children: [
                  if (ageText != null)
                    Text(
                      ageText,
                      style: AuroraType.labelSm.copyWith(
                        color: AuroraColors.inkTertiary,
                      ),
                    ),
                  const Spacer(),
                  if (remainingText != null)
                    Text(
                      remainingText,
                      style: AuroraType.labelSm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: remainingColor,
                      ),
                    ),
                ],
              ),
            ],

            // Divider.
            const SizedBox(height: AuroraSpacing.space2),
            const Divider(color: AuroraColors.inkBorder, height: 1, thickness: 0.5),
            const SizedBox(height: AuroraSpacing.space2),

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
                        color: AuroraColors.inkTertiary,
                      ),
                      Text(
                        '${_fmtCost(appliance.estimatedReplacementCost!)} purchased',
                        style: AuroraType.labelSm.copyWith(
                          color: AuroraColors.inkTertiary,
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
                      borderRadius: AuroraRadius.xs,
                    ),
                    child: Text(
                      badge.label,
                      style: AuroraType.labelSm.copyWith(
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
      backgroundColor: AuroraColors.coral,
      child: const Icon(Icons.add, color: AuroraColors.paper),
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
              style: AuroraType.h2.copyWith(color: AuroraColors.ink),
            ),
          ],
        ),
        const SizedBox(height: AuroraSpacing.space2),
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
        decoration: const BoxDecoration(
          color: AuroraColors.paper,
          borderRadius: AuroraRadius.lg,
          border: Border.fromBorderSide(
            BorderSide(color: AuroraColors.inkBorder, width: 1.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle_outline,
              size: 16,
              color: AuroraColors.inkTertiary,
            ),
            const SizedBox(width: AuroraSpacing.space2),
            Text(
              label,
              style: AuroraType.bodySm.copyWith(
                color: AuroraColors.inkTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
