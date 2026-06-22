import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/aurora/aurora.dart';

class SettingsNotificationsScreen extends StatefulWidget {
  const SettingsNotificationsScreen({super.key});

  @override
  State<SettingsNotificationsScreen> createState() =>
      _SettingsNotificationsScreenState();
}

class _SettingsNotificationsScreenState
    extends State<SettingsNotificationsScreen> {
  bool _pushEnabled = true;
  bool _quietHoursEnabled = true;
  bool _maintenanceReminders = true;
  bool _expirationAlerts = true;
  bool _weeklyDigest = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AuroraColors.paper,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AuroraColors.paper,
        border: null,
        middle: const Text('Notifications'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: const Text('Back'),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: () async {}),
            SliverToBoxAdapter(
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
                    // ── General section ───────────────────────────────────
                    const _SectionHeader(
                      dot: AuroraColors.yellow,
                      label: 'GENERAL',
                    ),
                    const SizedBox(height: AuroraSpacing.space3),
                    _TogglesGroup(children: [
                      AuroraToggleRow(
                        label: 'Push notifications',
                        value: _pushEnabled,
                        onChanged: (v) => setState(() => _pushEnabled = v),
                      ),
                      AuroraToggleRow(
                        label: 'Quiet hours',
                        helperText: '10pm – 8am',
                        value: _quietHoursEnabled,
                        onChanged: (v) =>
                            setState(() => _quietHoursEnabled = v),
                      ),
                    ]),

                    const SizedBox(height: AuroraSpacing.space10),

                    // ── Reminders section ─────────────────────────────────
                    const _SectionHeader(
                      dot: AuroraColors.lime,
                      label: 'REMINDERS',
                    ),
                    const SizedBox(height: AuroraSpacing.space3),
                    _TogglesGroup(children: [
                      AuroraToggleRow(
                        label: 'Maintenance reminders',
                        helperText: 'Tasks due soon',
                        value: _maintenanceReminders,
                        onChanged: (v) =>
                            setState(() => _maintenanceReminders = v),
                      ),
                      AuroraToggleRow(
                        label: 'Expiration alerts',
                        helperText: 'Documents expiring within 90 days',
                        value: _expirationAlerts,
                        onChanged: (v) =>
                            setState(() => _expirationAlerts = v),
                      ),
                      AuroraToggleRow(
                        label: 'Weekly digest',
                        helperText: 'Home health summary every Sunday',
                        value: _weeklyDigest,
                        onChanged: (v) => setState(() => _weeklyDigest = v),
                      ),
                    ]),
                  ],
                ),
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
            borderRadius: const BorderRadius.all(Radius.circular(2)),
          ),
        ),
        const SizedBox(width: 6),
        Text(label.toUpperCase(), style: AuroraType.label),
      ],
    );
  }
}

// ── Toggles group — stacked AuroraToggleRows with a divider ──────────────────

class _TogglesGroup extends StatelessWidget {
  const _TogglesGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1)
            const Divider(
              height: 1,
              thickness: 1,
              color: AuroraColors.inkBorder,
              indent: AuroraSpacing.screenPadH,
            ),
        ],
      ],
    );
  }
}
