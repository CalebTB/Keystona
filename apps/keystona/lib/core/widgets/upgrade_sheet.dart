import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text_styles.dart';

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

    if (count >= 3 && lastAtMs != null) {
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
          top: Radius.circular(AppSizes.radiusLg),
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
        padding: const EdgeInsets.fromLTRB(
          AppSizes.md,
          AppSizes.sm,
          AppSizes.md,
          AppSizes.xl,
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
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            // Gold home icon
            const Center(
              child: Icon(
                Icons.home_work_rounded,
                color: AppColors.goldAccent,
                size: AppSizes.iconXl,
              ),
            ),
            const SizedBox(height: AppSizes.md),
            // Headline
            Text(
              config.headline,
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),
            // Reason
            Text(
              config.reason,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.lg),
            // Features label
            Text(
              'With Premium, you get:',
              style: AppTextStyles.labelLarge
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSizes.sm),
            // Feature bullets
            ...config.features.map(
              (f) => Padding(
                padding:
                    const EdgeInsets.only(bottom: AppSizes.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\u2726 ',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.goldAccent),
                    ),
                    Expanded(
                      child: Text(
                        f,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            // Primary CTA
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.settingsPaywall);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.deepNavy,
                minimumSize:
                    const Size.fromHeight(AppSizes.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusSm),
                ),
              ),
              child: Text(
                'See Premium Plans',
                style: AppTextStyles.button
                    .copyWith(color: AppColors.textInverse),
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            // Dismiss button
            TextButton(
              onPressed: () {
                _recordDismissal(config.triggerKey);
                Navigator.of(context).pop();
              },
              child: Text(
                'Maybe Later',
                style: AppTextStyles.button
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
