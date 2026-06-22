import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/aurora/aurora.dart';
import '../../../services/supabase_service.dart';
import '../../home_profile/providers/home_profile_provider.dart';

class SettingsProfileScreen extends ConsumerWidget {
  const SettingsProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = SupabaseService.client.auth.currentUser;
    final overview = ref.watch(homeProfileProvider).value;

    final meta = user?.userMetadata;
    final fullName = (meta?['full_name'] as String? ?? '').trim().isNotEmpty
        ? meta!['full_name'] as String
        : '';
    final email = user?.email ?? '';
    final property = overview?.property;

    return CupertinoPageScaffold(
      backgroundColor: AuroraColors.paper,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AuroraColors.paper,
        border: null,
        middle: const Text('Profile & Home'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: const Text('Back'),
        ),
      ),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () async => ref.invalidate(homeProfileProvider),
          ),
          SliverSafeArea(
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AuroraSpacing.screenPadH,
                ).copyWith(
                  top: AuroraSpacing.space7,
                  bottom: AuroraSpacing.space10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Account section (form eyebrow: cobalt dot) ────────
                    _FormSectionHeader(label: 'ACCOUNT'),
                    const SizedBox(height: AuroraSpacing.space3),
                    _InfoGroup(rows: [
                      _InfoRow(
                        label: 'Name',
                        value: fullName.isEmpty ? '—' : fullName,
                      ),
                      _InfoRow(
                        label: 'Email',
                        value: email.isEmpty ? '—' : email,
                      ),
                    ]),

                    const SizedBox(height: AuroraSpacing.space10),

                    // ── Home section ──────────────────────────────────────
                    _FormSectionHeader(label: 'HOME'),
                    const SizedBox(height: AuroraSpacing.space3),
                    _InfoGroup(rows: [
                      _InfoRow(
                        label: 'Address',
                        value: property?.addressLine1 ?? '—',
                      ),
                      _InfoRow(
                        label: 'City',
                        value: property?.city ?? '—',
                      ),
                      _InfoRow(
                        label: 'State',
                        value: property?.state ?? '—',
                      ),
                      _InfoRow(
                        label: 'ZIP',
                        value: property?.zipCode ?? '—',
                      ),
                      _InfoRow(
                        label: 'Type',
                        value: property?.propertyType ?? '—',
                      ),
                      _InfoRow(
                        label: 'Year built',
                        value: property?.yearBuilt?.toString() ?? '—',
                      ),
                      _InfoRow(
                        label: 'Sq ft',
                        value: property?.squareFeet?.toString() ?? '—',
                      ),
                      _InfoRow(
                        label: 'Climate zone',
                        value: property?.climateZone != null
                            ? 'Zone ${property!.climateZone}'
                            : '—',
                      ),
                    ]),

                    const SizedBox(height: AuroraSpacing.space10),

                    // ── CTA row: cancel + save (cobalt) ───────────────────
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: 'Cancel',
                            onPressed: () => context.pop(),
                            expand: true,
                          ),
                        ),
                        const SizedBox(width: AuroraSpacing.space5),
                        Expanded(
                          child: SaveButton(
                            label: 'Edit home',
                            onPressed: () => context.push(AppRoutes.homeEdit),
                            expand: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Form section header — cobalt dot eyebrow ──────────────────────────────────

class _FormSectionHeader extends StatelessWidget {
  const _FormSectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AuroraColors.cobalt,
            borderRadius: AuroraRadius.xs,
          ),
        ),
        const SizedBox(width: AuroraSpacing.space2),
        Text(
          label.toUpperCase(),
          style: AuroraType.label.copyWith(color: AuroraColors.inkSecondary),
        ),
      ],
    );
  }
}

// ── Info group card ───────────────────────────────────────────────────────────

class _InfoGroup extends StatelessWidget {
  const _InfoGroup({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AuroraColors.butter,
        borderRadius: AuroraRadius.lg,
        border: Border.all(color: AuroraColors.inkBorder),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                color: AuroraColors.inkBorder,
                indent: AuroraSpacing.screenPadH,
              ),
          ],
        ],
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.screenPadH,
        vertical: AuroraSpacing.space3,
      ),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: AuroraType.label.copyWith(color: AuroraColors.inkSecondary),
          ),
          const Spacer(),
          Text(value, style: AuroraType.body),
        ],
      ),
    );
  }
}
