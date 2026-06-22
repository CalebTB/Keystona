import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../router/app_router.dart';
import '../theme/aurora_colors.dart';
import '../theme/aurora_radius.dart';
import '../theme/aurora_typography.dart';

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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0DFEA),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Gold home icon
            const Center(
              child: Icon(
                Icons.home_work_rounded,
                color: AuroraColors.yellow,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            // Headline
            Text(
              config.headline,
              style: AuroraType.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Reason
            Text(
              config.reason,
              style: AuroraType.body.copyWith(color: AuroraColors.inkSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Features label
            Text(
              'With Premium, you get:',
              style: AuroraType.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            // Feature bullets
            ...config.features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✦ ',
                      style: AuroraType.body.copyWith(
                        color: AuroraColors.yellow,
                      ),
                    ),
                    Expanded(
                      child: Text(f, style: AuroraType.body),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Primary CTA
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.settingsPaywall);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AuroraColors.coral,
                minimumSize: const Size.fromHeight(48),
                shape: const RoundedRectangleBorder(
                  borderRadius: AuroraRadius.sm,
                ),
              ),
              child: Text(
                'See Premium Plans',
                style: AuroraType.bodyLg.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Dismiss button
            TextButton(
              onPressed: () {
                _recordDismissal(config.triggerKey);
                Navigator.of(context).pop();
              },
              child: Text(
                'Maybe Later',
                style: AuroraType.bodyLg.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AuroraColors.inkSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
