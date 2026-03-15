import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text_styles.dart';
import '../../features/subscription/providers/subscription_provider.dart';

/// Displays a contextual banner at the top of the Home Profile screen.
///
/// Two states:
/// - **Trial banner**: gold background — shown when trial ends in <= 5 days.
/// - **Grace banner**: amber background — shown during the 14-day grace period.
///
/// Dismissible per session (the banner hides for the current app session only;
/// no persistence). Returns [SizedBox.shrink] when no banner is needed or while
/// the trial status is loading.
class TrialBanner extends ConsumerStatefulWidget {
  const TrialBanner({super.key});

  @override
  ConsumerState<TrialBanner> createState() => _TrialBannerState();
}

class _TrialBannerState extends ConsumerState<TrialBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final statusAsync = ref.watch(trialStatusProvider);

    return statusAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (status) {
        if (status.shouldShowGraceBanner) {
          return _GraceBanner(
            daysUntilArchive: status.daysUntilArchive,
            onDismiss: () => setState(() => _dismissed = true),
            onUpgrade: () => context.push(AppRoutes.settingsPaywall),
          );
        }
        if (status.shouldShowTrialBanner) {
          return _TrialEndingBanner(
            daysRemaining: status.daysRemainingInTrial,
            onDismiss: () => setState(() => _dismissed = true),
            onView: () => context.push(AppRoutes.settingsSubscription),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ── Trial-ending banner ───────────────────────────────────────────────────────

class _TrialEndingBanner extends StatelessWidget {
  const _TrialEndingBanner({
    required this.daysRemaining,
    required this.onDismiss,
    required this.onView,
  });

  final int daysRemaining;
  final VoidCallback onDismiss;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.goldAccent,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Your Premium trial ends in $daysRemaining day${daysRemaining == 1 ? '' : 's'}.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.deepNavy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          GestureDetector(
            onTap: onView,
            child: Text(
              'View',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.deepNavy,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.deepNavy,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(
              Icons.close,
              size: AppSizes.iconSm,
              color: AppColors.deepNavy.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grace period banner ───────────────────────────────────────────────────────

class _GraceBanner extends StatelessWidget {
  const _GraceBanner({
    required this.daysUntilArchive,
    required this.onDismiss,
    required this.onUpgrade,
  });

  final int daysUntilArchive;
  final VoidCallback onDismiss;
  final VoidCallback onUpgrade;

  // Amber background — Bootstrap-style warning palette, not a hardcoded brand color.
  static const _background = Color(0xFFFFF3CD);
  static const _foreground = Color(0xFF856404);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: _foreground.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '\u26A0 $daysUntilArchive document${daysUntilArchive == 1 ? '' : 's'} '
              'will be archived in $daysUntilArchive days.',
              style: AppTextStyles.bodyMedium.copyWith(color: _foreground),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          GestureDetector(
            onTap: onUpgrade,
            child: Text(
              'Upgrade',
              style: AppTextStyles.labelMedium.copyWith(
                color: _foreground,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: _foreground,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(
              Icons.close,
              size: AppSizes.iconSm,
              color: _foreground.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
