import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';

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
      backgroundColor: AppColors.warmOffWhite,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.warmOffWhite,
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
        child: ListView(
          padding: AppPadding.screen.copyWith(top: AppSizes.md),
          children: [
            _label('GENERAL'),
            const SizedBox(height: AppSizes.sm),
            _group([
              _toggle(
                icon: CupertinoIcons.bell,
                color: AppColors.sandAmber,
                title: 'Push notifications',
                value: _pushEnabled,
                onChanged: (v) => setState(() => _pushEnabled = v),
              ),
              _toggle(
                icon: CupertinoIcons.moon,
                color: AppColors.sandAmber,
                title: 'Quiet hours',
                subtitle: '10pm – 8am',
                value: _quietHoursEnabled,
                onChanged: (v) => setState(() => _quietHoursEnabled = v),
              ),
            ]),

            const SizedBox(height: AppSizes.xl),

            _label('REMINDERS'),
            const SizedBox(height: AppSizes.sm),
            _group([
              _toggle(
                icon: CupertinoIcons.wrench,
                color: AppColors.olive,
                title: 'Maintenance reminders',
                subtitle: 'Tasks due soon',
                value: _maintenanceReminders,
                onChanged: (v) => setState(() => _maintenanceReminders = v),
              ),
              _toggle(
                icon: CupertinoIcons.doc_text,
                color: AppColors.accent,
                title: 'Expiration alerts',
                subtitle: 'Documents expiring within 90 days',
                value: _expirationAlerts,
                onChanged: (v) => setState(() => _expirationAlerts = v),
              ),
              _toggle(
                icon: CupertinoIcons.chart_bar,
                color: AppColors.plum,
                title: 'Weekly digest',
                subtitle: 'Home health summary every Sunday',
                value: _weeklyDigest,
                onChanged: (v) => setState(() => _weeklyDigest = v),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: AppTextStyles.monoSection);

  Widget _group(List<Widget> rows) {
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
                  indent: 54),
          ],
        ],
      ),
    );
  }

  Widget _toggle({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium),
                if (subtitle != null)
                  Text(subtitle,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: AppColors.olive,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
