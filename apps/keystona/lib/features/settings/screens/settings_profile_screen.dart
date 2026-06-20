import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
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
      backgroundColor: AppColors.warmOffWhite,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.warmOffWhite,
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
                padding: AppPadding.screen.copyWith(top: AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('ACCOUNT'),
                    const SizedBox(height: AppSizes.sm),
                    _InfoGroup(rows: [
                      _InfoRow(
                          label: 'Name',
                          value: fullName.isEmpty ? '—' : fullName),
                      _InfoRow(
                          label: 'Email',
                          value: email.isEmpty ? '—' : email),
                    ]),

                    const SizedBox(height: AppSizes.xl),

                    _SectionLabel('HOME'),
                    const SizedBox(height: AppSizes.sm),
                    _InfoGroup(rows: [
                      _InfoRow(
                          label: 'Address',
                          value: property?.addressLine1 ?? '—'),
                      _InfoRow(label: 'City', value: property?.city ?? '—'),
                      _InfoRow(label: 'State', value: property?.state ?? '—'),
                      _InfoRow(
                          label: 'ZIP', value: property?.zipCode ?? '—'),
                      _InfoRow(
                          label: 'Type',
                          value: property?.propertyType ?? '—'),
                      _InfoRow(
                          label: 'Year built',
                          value: property?.yearBuilt?.toString() ?? '—'),
                      _InfoRow(
                          label: 'Sq ft',
                          value: property?.squareFeet?.toString() ?? '—'),
                      _InfoRow(
                          label: 'Climate zone',
                          value: property?.climateZone != null
                              ? 'Zone ${property!.climateZone}'
                              : '—'),
                    ]),

                    const SizedBox(height: AppSizes.xl),

                    GestureDetector(
                      onTap: () => context.push(AppRoutes.homeEdit),
                      child: Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.deepNavy,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusCard),
                        ),
                        child: Text(
                          'Edit home details',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMediumSemibold
                              .copyWith(color: AppColors.textInverse),
                        ),
                      ),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyles.monoSection);
  }
}

class _InfoGroup extends StatelessWidget {
  const _InfoGroup({required this.rows});
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              const Divider(
                  height: 1, thickness: 1, color: AppColors.warmFill,
                  indent: 16),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Text(label,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
