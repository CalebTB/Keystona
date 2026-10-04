import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../router/app_router.dart';
import '../theme/aurora_colors.dart';
import '../theme/aurora_radius.dart';
import '../theme/aurora_spacing.dart';
import '../theme/aurora_typography.dart';
import 'aurora/aurora_button.dart';
import 'aurora/aurora_sheet.dart';

/// Configuration for an [UpgradeSheet] presentation.
class UpgradeSheetConfig {
  const UpgradeSheetConfig({
    required this.headline,
    required this.reason,
    required this.features,
    required this.triggerKey,
  });

  /// Short title for the sheet, e.g. "Unlock Unlimited Documents".
  final String headline;

  /// Sentence explaining why the gate was triggered.
  final String reason;

  /// Bullet-list items describing what Premium unlocks.
  final List<String> features;

  /// Unique key used for dismissal-count tracking in SharedPreferences.
  final String triggerKey;
}

/// Full-featured premium upsell bottom sheet.
///
/// Call via [UpgradeSheet.show]. The static method checks dismissal history
/// and silently returns if the user has dismissed >= 3 times within 7 days.
class UpgradeSheet extends StatelessWidget {
  const UpgradeSheet._({required this.config});

  final UpgradeSheetConfig config;

  // ── SharedPreferences keys ────────────────────────────────────────────────

  static String _countKey(String key) => 'upgrade_dismissed_count_$key';
  static String _atKey(String key) => 'upgrade_dismissed_at_$key';

  // ── Static show ───────────────────────────────────────────────────────────

  /// Presents the upgrade sheet as a modal bottom sheet.
  ///
  /// Silently returns without presenting if the user has dismissed this sheet
  /// 3 or more times AND the last dismissal was within the last 7 days.
  static Future<void> show(
    BuildContext context, {
    required UpgradeSheetConfig config,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final countKey = _countKey(config.triggerKey);
    final atKey = _atKey(config.triggerKey);

    final count = prefs.getInt(countKey) ?? 0;
    final lastAtMs = prefs.getInt(atKey);

    if (count >= 99 && lastAtMs != null) {
      final lastDismissed =
          DateTime.fromMillisecondsSinceEpoch(lastAtMs);
      final daysSince =
          DateTime.now().difference(lastDismissed).inDays;
      if (daysSince < 7) return;
    }

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AuroraColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: AuroraSheet.topRadius(context),
      ),
      builder: (sheetContext) => UpgradeSheet._(config: config),
    );
  }

  // ── Dismissal tracking ────────────────────────────────────────────────────

  static Future<void> _recordDismissal(String triggerKey) async {
    final prefs = await SharedPreferences.getInstance();
    final countKey = _countKey(triggerKey);
    final atKey = _atKey(triggerKey);
    final current = prefs.getInt(countKey) ?? 0;
    await prefs.setInt(countKey, current + 1);
    await prefs.setInt(
      atKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AuroraSpacing.screenPadH,
          AuroraSpacing.space3,
          AuroraSpacing.screenPadH,
          AuroraSpacing.space10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: const BoxDecoration(
                  color: AuroraColors.inkBorder,
                  borderRadius: AuroraRadius.full,
                ),
              ),
            ),
            const SizedBox(height: AuroraSpacing.space9),
            // Coral upgrade hero card with yellow blob
            _UpgradeHeroCard(
              headline: config.headline,
              reason: config.reason,
            ),
            const SizedBox(height: AuroraSpacing.space9),
            // Features label
            Text(
              'WITH PREMIUM, YOU GET',
              style: AuroraType.label.copyWith(
                color: AuroraColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AuroraSpacing.space5),
            // Feature bullets with lime icon tiles
            ...config.features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: AuroraSpacing.space5),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AuroraColors.limeDim,
                        borderRadius: AuroraRadius.xs,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: AuroraColors.limeDeep,
                        ),
                      ),
                    ),
                    const SizedBox(width: AuroraSpacing.space5),
                    Expanded(
                      child: Text(f, style: AuroraType.body),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AuroraSpacing.space9),
            // Primary CTA — PrimaryButton (coral) for purchase action
            PrimaryButton(
              label: 'See Premium Plans',
              expand: true,
              onPressed: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.settingsPaywall);
              },
            ),
            const SizedBox(height: AuroraSpacing.space1),
            // Dismiss — GhostButton
            GhostButton(
              label: 'Maybe Later',
              onPressed: () {
                _recordDismissal(config.triggerKey);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Coral hero card with yellow blob ─────────────────────────────────────────

class _UpgradeHeroCard extends StatelessWidget {
  const _UpgradeHeroCard({
    required this.headline,
    required this.reason,
  });

  final String headline;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AuroraRadius.xxl,
      child: Stack(
        children: [
          // Coral background
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AuroraColors.coral,
              borderRadius: AuroraRadius.xxl,
            ),
            padding: const EdgeInsets.all(AuroraSpacing.space8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PRO badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: const BoxDecoration(
                    color: AuroraColors.lime,
                    borderRadius: AuroraRadius.xs,
                  ),
                  child: Text(
                    'PRO',
                    style: AuroraType.labelSm.copyWith(
                      color: AuroraColors.limeDeep,
                    ),
                  ),
                ),
                const SizedBox(height: AuroraSpacing.space5),
                Text(
                  headline,
                  style: AuroraType.h2.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AuroraSpacing.space2),
                Text(
                  reason,
                  style: AuroraType.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          // Yellow decorative blob
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AuroraColors.yellow.withValues(alpha: 0.32),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
