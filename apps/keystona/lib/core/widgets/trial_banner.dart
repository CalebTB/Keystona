import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../theme/aurora_colors.dart';
import '../theme/aurora_radius.dart';
import '../theme/aurora_spacing.dart';
import '../theme/aurora_typography.dart';
import '../../features/subscription/providers/subscription_provider.dart';

/// Contextual banner displayed at the top of the Home Profile screen.
///
/// Two states:
/// - **Trial banner**: coral background — shown when trial ends in <= 5 days.
/// - **Grace banner**: yellowDim background — shown during the 14-day grace period.
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
      margin: const EdgeInsets.only(bottom: AuroraSpacing.space7),
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.screenPadH,
        vertical: AuroraSpacing.space3,
      ),
      decoration: const BoxDecoration(
        color: AuroraColors.coral,
        borderRadius: AuroraRadius.lg,
      ),
      child: Row(
        children: [
          // PRO badge in lime JetBrains Mono
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          const SizedBox(width: AuroraSpacing.space3),
          Expanded(
            child: Text(
              'Trial ends in $daysRemaining day${daysRemaining == 1 ? '' : 's'}.',
              style: AuroraType.body.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AuroraSpacing.space3),
          // GhostButton-style link — white text on coral
          GestureDetector(
            onTap: onView,
            child: Text(
              'View',
              style: AuroraType.bodySm.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AuroraSpacing.space3),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(
              Icons.close,
              size: 16,
              color: Colors.white.withValues(alpha: 0.7),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AuroraSpacing.space7),
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.screenPadH,
        vertical: AuroraSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: AuroraColors.coralDim,
        borderRadius: AuroraRadius.lg,
        border: Border.all(color: AuroraColors.coral.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PRO badge in lime JetBrains Mono
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          const SizedBox(width: AuroraSpacing.space3),
          Expanded(
            child: Text(
              '$daysUntilArchive document${daysUntilArchive == 1 ? '' : 's'} '
              'will be archived in $daysUntilArchive days.',
              style: AuroraType.body.copyWith(color: AuroraColors.coral),
            ),
          ),
          const SizedBox(width: AuroraSpacing.space3),
          GestureDetector(
            onTap: onUpgrade,
            child: Text(
              'Upgrade',
              style: AuroraType.bodySm.copyWith(
                color: AuroraColors.coral,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: AuroraColors.coral,
              ),
            ),
          ),
          const SizedBox(width: AuroraSpacing.space3),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(
              Icons.close,
              size: 16,
              color: AuroraColors.coral.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
