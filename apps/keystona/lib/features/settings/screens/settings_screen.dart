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
import '../../../services/providers/service_providers.dart';
import '../../../services/supabase_service.dart';
import '../../home_profile/providers/home_profile_provider.dart';
import '../../subscription/providers/subscription_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = SupabaseService.client.auth.currentUser;
    final overview = ref.watch(homeProfileProvider).value;
    final trial = ref.watch(trialStatusProvider).value;
    final isPremium = trial?.subscriptionTier == 'premium';

    final email = user?.email ?? '';
    final meta = user?.userMetadata;
    final fullName =
        (meta?['full_name'] as String? ?? '').trim().isNotEmpty
            ? meta!['full_name'] as String
            : email.isNotEmpty
                ? email.split('@').first
                : 'You';

    final initials = _initials(fullName);

    final property = overview?.property;
    final address = property?.addressLine1 ?? 'Add your home';
    final addressSub = property != null
        ? '${property.city}, ${property.state}'
            '${property.climateZone != null ? ' · Zone ${property.climateZone}' : ''}'
        : 'Not set';

    return CupertinoPageScaffold(
      backgroundColor: AuroraColors.paper,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            backgroundColor: AuroraColors.paper,
            border: null,
            largeTitle: const Text('Settings'),
          ),
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              ref.invalidate(homeProfileProvider);
              ref.invalidate(trialStatusProvider);
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AuroraSpacing.screenPadH,
              ).copyWith(
                top: AuroraSpacing.space3,
                bottom: AuroraSpacing.space10 + 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Account card (ink bg, coral avatar) ──────────────────
                  _AccountCard(
                    initials: initials,
                    fullName: fullName,
                    email: email,
                    isPremium: isPremium,
                    onTap: () => context.push(AppRoutes.settingsProfile),
                  ),

                  // ── PRO upgrade card (shown only to free users) ──────────
                  if (!isPremium) ...[
                    const SizedBox(height: AuroraSpacing.space5),
                    _ProUpgradeCard(
                      onUpgrade: () =>
                          context.push(AppRoutes.settingsSubscription),
                    ),
                  ],

                  const SizedBox(height: AuroraSpacing.space10),

                  // ── Property section ─────────────────────────────────────
                  const _SectionHeader(
                    dot: AuroraColors.lime,
                    label: 'PROPERTY',
                  ),
                  const SizedBox(height: AuroraSpacing.space3),
                  _SettingsGroup(rows: [
                    _SettingsRow(
                      iconBg: AuroraColors.limeDim,
                      iconColor: AuroraColors.limeDeep,
                      icon: CupertinoIcons.house,
                      title: address,
                      subtitle: addressSub,
                      onTap: () => context.push(AppRoutes.settingsProfile),
                    ),
                    _SettingsRow(
                      iconBg: AuroraColors.limeDim,
                      iconColor: AuroraColors.limeDeep,
                      icon: CupertinoIcons.person_2,
                      title: 'Household members',
                      subtitle: 'Manage who has access',
                      onTap: () => context.push(AppRoutes.settingsHousehold),
                    ),
                  ]),

                  const SizedBox(height: AuroraSpacing.space10),

                  // ── Notifications section ────────────────────────────────
                  const _SectionHeader(
                    dot: AuroraColors.yellow,
                    label: 'NOTIFICATIONS',
                  ),
                  const SizedBox(height: AuroraSpacing.space3),
                  _SettingsGroup(rows: [
                    _ToggleRow(
                      iconBg: AuroraColors.yellowDim,
                      iconColor: AuroraColors.yellowDeep,
                      icon: CupertinoIcons.bell,
                      title: 'Push notifications',
                      onToggle: (v) {},
                    ),
                    _SettingsRow(
                      iconBg: AuroraColors.yellowDim,
                      iconColor: AuroraColors.yellowDeep,
                      icon: CupertinoIcons.moon,
                      title: 'Quiet hours',
                      subtitle: '10pm – 8am',
                      onTap: () =>
                          context.push(AppRoutes.settingsNotifications),
                    ),
                  ]),

                  const SizedBox(height: AuroraSpacing.space10),

                  // ── Subscription section ─────────────────────────────────
                  const _SectionHeader(
                    dot: AuroraColors.cobalt,
                    label: 'SUBSCRIPTION',
                  ),
                  const SizedBox(height: AuroraSpacing.space3),
                  _SettingsGroup(rows: [
                    _SettingsRow(
                      iconBg: AuroraColors.cobaltDim,
                      iconColor: AuroraColors.cobalt,
                      icon: CupertinoIcons.star,
                      title: 'Manage plan',
                      subtitle: isPremium
                          ? 'Premium · renews Sep 12'
                          : 'Free plan · Upgrade to Pro',
                      onTap: () =>
                          context.push(AppRoutes.settingsSubscription),
                    ),
                  ]),

                  const SizedBox(height: AuroraSpacing.space10),

                  // ── Privacy section ──────────────────────────────────────
                  const _SectionHeader(
                    dot: AuroraColors.cobalt,
                    label: 'PRIVACY',
                  ),
                  const SizedBox(height: AuroraSpacing.space3),
                  _SettingsGroup(rows: [
                    _SettingsRow(
                      iconBg: AuroraColors.cobaltDim,
                      iconColor: AuroraColors.cobalt,
                      icon: CupertinoIcons.arrow_down_circle,
                      title: 'Export my data',
                      onTap: () => context.push(AppRoutes.settingsExport),
                    ),
                  ]),

                  const SizedBox(height: AuroraSpacing.space3),

                  // ── Danger zone — ghost text only, no icon group ─────────
                  GestureDetector(
                    onTap: () =>
                        context.push(AppRoutes.settingsDeleteAccount),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AuroraSpacing.space6,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: AuroraColors.coralDim,
                        borderRadius: AuroraRadius.lg,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AuroraColors.coral.withValues(alpha: 0.15),
                              borderRadius: AuroraRadius.sm,
                            ),
                            child: const Icon(
                              CupertinoIcons.trash,
                              size: 14,
                              color: AuroraColors.coral,
                            ),
                          ),
                          const SizedBox(width: AuroraSpacing.space5),
                          Expanded(
                            child: Text(
                              'Delete account',
                              style: AuroraType.body.copyWith(
                                color: AuroraColors.coral,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            CupertinoIcons.chevron_right,
                            size: 14,
                            color: AuroraColors.coral.withValues(alpha: 0.55),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AuroraSpacing.space10),

                  // ── Sign out ─────────────────────────────────────────────
                  _SignOutButton(ref: ref),

                  const SizedBox(height: AuroraSpacing.space7),

                  Center(
                    child: Text(
                      'Keystona · v1.0.0',
                      style: AuroraType.bodySm.copyWith(
                        color: AuroraColors.inkTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }
}

// ── Account card — ink bg, coral avatar ──────────────────────────────────────

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.initials,
    required this.fullName,
    required this.email,
    required this.isPremium,
    required this.onTap,
  });

  final String initials;
  final String fullName;
  final String email;
  final bool isPremium;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AuroraSpacing.space7),
        decoration: BoxDecoration(
          color: AuroraColors.ink,
          borderRadius: AuroraRadius.xl,
        ),
        child: Row(
          children: [
            // Coral avatar circle
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: AuroraColors.coral,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: AuroraType.h2.copyWith(color: AuroraColors.paper),
                ),
              ),
            ),
            const SizedBox(width: AuroraSpacing.space6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: AuroraType.h3.copyWith(color: AuroraColors.paper),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: AuroraType.bodySm.copyWith(
                      color: AuroraColors.paper.withValues(alpha: 0.65),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isPremium) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AuroraColors.lime.withValues(alpha: 0.18),
                        borderRadius: AuroraRadius.xs,
                      ),
                      child: Text(
                        'PRO',
                        style: AuroraType.labelSm.copyWith(
                          color: AuroraColors.lime,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 15,
              color: AuroraColors.paper.withValues(alpha: 0.40),
            ),
          ],
        ),
      ),
    );
  }
}

// ── PRO upgrade card — coral bg with yellow blob ──────────────────────────────

class _ProUpgradeCard extends StatelessWidget {
  const _ProUpgradeCard({required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AuroraColors.coral,
        borderRadius: AuroraRadius.xl,
      ),
      child: ClipRRect(
        borderRadius: AuroraRadius.xl,
        child: Stack(
          children: [
            // Yellow decorative blob top-right
            Positioned(
              top: -24,
              right: -24,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AuroraColors.yellow.withValues(alpha: 0.32),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AuroraSpacing.space7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AuroraColors.lime.withValues(alpha: 0.2),
                      borderRadius: AuroraRadius.xs,
                    ),
                    child: Text(
                      'PRO',
                      style: AuroraType.labelSm.copyWith(
                        color: AuroraColors.lime,
                      ),
                    ),
                  ),
                  const SizedBox(height: AuroraSpacing.space3),
                  Text(
                    'Unlock the full picture',
                    style: AuroraType.h3.copyWith(color: AuroraColors.paper),
                  ),
                  const SizedBox(height: AuroraSpacing.space2),
                  Text(
                    'Unlimited docs · AI maintenance plans · Priority alerts',
                    style: AuroraType.body.copyWith(
                      color: AuroraColors.paper.withValues(alpha: 0.80),
                    ),
                  ),
                  const SizedBox(height: AuroraSpacing.space7),
                  PrimaryButton(
                    label: 'Upgrade to Pro',
                    onPressed: onUpgrade,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header — dot + label ──────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.dot, required this.label});

  final Color dot;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: dot,
            borderRadius: AuroraRadius.xs,
          ),
        ),
        const SizedBox(width: 6),
        Text(label.toUpperCase(), style: AuroraType.label),
      ],
    );
  }
}

// ── Settings group card ───────────────────────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.rows});

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
              Divider(
                height: 1,
                thickness: 1,
                color: AuroraColors.inkBorder,
                indent: AuroraSpacing.space6 + 28 + AuroraSpacing.space5,
              ),
          ],
        ],
      ),
    );
  }
}

// ── Standard settings row ─────────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AuroraSpacing.space6,
          vertical: 13,
        ),
        child: Row(
          children: [
            // 28×28 icon tile
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: AuroraRadius.sm,
              ),
              child: Icon(icon, size: 14, color: iconColor),
            ),
            const SizedBox(width: AuroraSpacing.space5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AuroraType.body),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: AuroraType.bodySm.copyWith(
                        color: AuroraColors.inkSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: AuroraColors.inkTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Toggle row ────────────────────────────────────────────────────────────────

class _ToggleRow extends StatefulWidget {
  const _ToggleRow({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.onToggle,
  });

  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final ValueChanged<bool> onToggle;

  @override
  State<_ToggleRow> createState() => _ToggleRowState();
}

class _ToggleRowState extends State<_ToggleRow> {
  bool _value = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.space6,
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: widget.iconBg,
              borderRadius: AuroraRadius.sm,
            ),
            child: Icon(widget.icon, size: 14, color: widget.iconColor),
          ),
          const SizedBox(width: AuroraSpacing.space5),
          Expanded(
            child: Text(widget.title, style: AuroraType.body),
          ),
          CupertinoSwitch(
            value: _value,
            activeTrackColor: AuroraColors.coral,
            onChanged: (v) {
              setState(() => _value = v);
              widget.onToggle(v);
            },
          ),
        ],
      ),
    );
  }
}

// ── Sign out ──────────────────────────────────────────────────────────────────

class _SignOutButton extends ConsumerWidget {
  const _SignOutButton({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        final confirmed = await showCupertinoDialog<bool>(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('Sign out?'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sign out'),
              ),
            ],
          ),
        );
        if (confirmed != true || !context.mounted) return;
        await ref.read(authServiceProvider).signOut();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AuroraColors.paper,
          borderRadius: AuroraRadius.lg,
          border: Border.all(color: AuroraColors.inkBorderStrong),
        ),
        child: Text(
          'Sign out',
          textAlign: TextAlign.center,
          style: AuroraType.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AuroraColors.coral,
          ),
        ),
      ),
    );
  }
}
