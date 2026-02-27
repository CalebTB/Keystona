import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../providers/onboarding_provider.dart';

/// Screen 3 of onboarding — premium trial offer.
///
/// RevenueCat purchase is wired in Phase 6. For now both CTAs simply
/// mark onboarding complete and navigate to the dashboard.
class TrialScreen extends StatelessWidget {
  const TrialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          child: Column(
            children: [
              const Spacer(),

              // ── Title ────────────────────────────────────────────────────
              Text(
                'Try Premium Free',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSizes.sm),

              // ── Subtitle ─────────────────────────────────────────────────
              Text(
                r'30 days free, then $4.99/month. Cancel anytime.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSizes.xl),

              // ── Benefit bullets ──────────────────────────────────────────
              _BulletRow(text: 'Unlimited document storage'),
              const SizedBox(height: AppSizes.md),
              _BulletRow(text: 'Smart maintenance reminders'),
              const SizedBox(height: AppSizes.md),
              _BulletRow(text: 'Emergency hub for your whole household'),

              const Spacer(),

              // ── Start Free Trial CTA ─────────────────────────────────────
              ElevatedButton(
                onPressed: () => _complete(context),
                child: const Text('Start Free Trial'),
              ),

              const SizedBox(height: AppSizes.sm),

              // ── No thanks ────────────────────────────────────────────────
              TextButton(
                onPressed: () => _complete(context),
                child: const Text('No thanks'),
              ),

              const SizedBox(height: AppSizes.md),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _complete(BuildContext context) async {
    try {
      await completeOnboarding();
    } catch (_) {
      // Best-effort — do not block navigation on a metadata write failure.
      if (context.mounted) {
        SnackbarService.showError(
          context,
          'Could not save setup status. You can always set up later.',
        );
      }
    } finally {
      if (context.mounted) {
        context.go(AppRoutes.dashboard);
      }
    }
  }
}

/// A single bullet row: checkmark icon + descriptive text.
class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: AppSizes.iconMd,
          color: AppColors.success,
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Text(text, style: AppTextStyles.bodyMedium),
        ),
      ],
    );
  }
}
