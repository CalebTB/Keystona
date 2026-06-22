import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
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
              padding: const EdgeInsets.all(AuroraSpacing.screenPadH).copyWith(
                top: AuroraSpacing.space3,
                bottom: 48,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AccountCard(
                    initials: initials,
                    fullName: fullName,
                    email: email,
                    isPremium: isPremium,
                    onTap: () => context.push(AppRoutes.settingsProfile),
                  ),

                  const SizedBox(height: AuroraSpacing.space10),

                  _GroupLabel(dot: AuroraColors.lime, label: 'PROPERTY'),
                  const SizedBox(height: AuroraSpacing.space3),
                  _SettingsGroup(rows: [
                    _SettingsRow(
                      iconColor: AuroraColors.lime,
                      icon: CupertinoIcons.house,
                      title: address,
                      subtitle: addressSub,
                      onTap: () => context.push(AppRoutes.settingsProfile),
                    ),
                    _SettingsRow(
                      iconColor: AuroraColors.lime,
                      icon: CupertinoIcons.person_2,
                      title: 'Household members',
                      subtitle: 'Manage who has access',
                      onTap: () => context.push(AppRoutes.settingsHousehold),
                    ),
                  ]),

                  const SizedBox(height: AuroraSpacing.space10),

                  _GroupLabel(dot: AuroraColors.yellowDeep, label: 'NOTIFICATIONS'),
                  const SizedBox(height: AuroraSpacing.space3),
                  _SettingsGroup(rows: [
                    _ToggleRow(
                      iconColor: AuroraColors.yellowDeep,
                      icon: CupertinoIcons.bell,
                      title: 'Push notifications',
                      onToggle: (v) {},
                    ),
                    _SettingsRow(
                      iconColor: AuroraColors.yellowDeep,
                      icon: CupertinoIcons.moon,
                      title: 'Quiet hours',
                      subtitle: '10pm – 8am',
                      onTap: () => context.push(AppRoutes.settingsNotifications),
                    ),
                  ]),

                  const SizedBox(height: AuroraSpacing.space10),

                  _GroupLabel(dot: AuroraColors.cobalt, label: 'SUBSCRIPTION'),
                  const SizedBox(height: AuroraSpacing.space3),
                  _SettingsGroup(rows: [
                    _SettingsRow(
                      iconColor: AuroraColors.cobalt,
                      icon: CupertinoIcons.star,
                      title: 'Manage plan',
                      subtitle: isPremium
                          ? 'Premium · renews Sep 12'
                          : 'Free plan · Upgrade to Pro',
                      onTap: () => context.push(AppRoutes.settingsSubscription),
                    ),
                  ]),

                  const SizedBox(height: AuroraSpacing.space10),

                  _GroupLabel(dot: AuroraColors.cobalt, label: 'PRIVACY'),
                  const SizedBox(height: AuroraSpacing.space3),
                  _SettingsGroup(rows: [
                    _SettingsRow(
                      iconColor: AuroraColors.cobalt,
                      icon: CupertinoIcons.arrow_down_circle,
                      title: 'Export my data',
                      onTap: () => context.push(AppRoutes.settingsExport),
                    ),
                    _SettingsRow(
                      iconColor: AuroraColors.coral,
                      icon: CupertinoIcons.trash,
                      title: 'Delete account',
                      titleColor: AuroraColors.coral,
                      danger: true,
                      onTap: () =>
                          context.push(AppRoutes.settingsDeleteAccount),
                    ),
                  ]),

                  const SizedBox(height: AuroraSpacing.space10),

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

// ── Account card ──────────────────────────────────────────────────────────────

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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AuroraColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AuroraColors.inkBorder, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AuroraColors.coral, AuroraColors.yellow],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: AuroraType.bodyLg.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: AuroraType.bodySm.copyWith(
                      color: AuroraColors.inkSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isPremium) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AuroraColors.yellowDim,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AuroraColors.yellowDeep.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.star_fill,
                              size: 10, color: AuroraColors.yellowDeep),
                          const SizedBox(width: 4),
                          Text(
                            'PREMIUM · ANNUAL',
                            style: AuroraType.label.copyWith(
                              color: AuroraColors.yellowDeep,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right,
                size: 16, color: AuroraColors.inkTertiary),
          ],
        ),
      ),
    );
  }
}

// ── Group label ───────────────────────────────────────────────────────────────

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.dot, required this.label});
  final Color dot;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AuroraType.label),
      ],
    );
  }
}

// ── Settings group (card with dividers) ───────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.rows});
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AuroraColors.inkBorder, width: 1.5),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              const Divider(
                  height: 1, thickness: 1, color: AuroraColors.butter,
                  indent: 54),
          ],
        ],
      ),
    );
  }
}

// ── Standard settings row ─────────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.iconColor,
    required this.icon,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.danger = false,
    this.onTap,
  });

  final Color iconColor;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: danger
            ? AuroraColors.coral.withValues(alpha: 0.04)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            _IconBlock(color: iconColor, icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AuroraType.body.copyWith(
                      color: titleColor ?? AuroraColors.ink,
                    ),
                  ),
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
            const Icon(CupertinoIcons.chevron_right,
                size: 15, color: AuroraColors.inkTertiary),
          ],
        ),
      ),
    );
  }
}

// ── Toggle row ────────────────────────────────────────────────────────────────

class _ToggleRow extends StatefulWidget {
  const _ToggleRow({
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.onToggle,
  });

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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _IconBlock(color: widget.iconColor, icon: widget.icon),
          const SizedBox(width: 12),
          Expanded(
            child: Text(widget.title, style: AuroraType.body),
          ),
          CupertinoSwitch(
            value: _value,
            activeTrackColor: AuroraColors.lime,
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

// ── Icon block ────────────────────────────────────────────────────────────────

class _IconBlock extends StatelessWidget {
  const _IconBlock({required this.color, required this.icon});
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: 16, color: color),
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
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AuroraColors.inkBorder, width: 1.5),
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
