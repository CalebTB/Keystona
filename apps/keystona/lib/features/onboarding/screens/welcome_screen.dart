import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../providers/onboarding_provider.dart';

/// First onboarding screen. No app bar — full-bleed centered layout.
///
/// Routes:
///   "Get Started" → [AppRoutes.onboardingProperty]
///   "Skip setup"  → marks onboarding complete then → [AppRoutes.dashboard]
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          child: Column(
            children: [
              const Spacer(),

              // ── App name ────────────────────────────────────────────────────
              Text(
                'Keystona',
                style: AppTextStyles.displayLarge,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSizes.sm),

              // ── Tagline ─────────────────────────────────────────────────────
              Text(
                'The smart way to manage your home.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // ── Get Started CTA ─────────────────────────────────────────────
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.onboardingProperty),
                child: const Text('Get Started'),
              ),

              const SizedBox(height: AppSizes.sm),

              // ── Skip setup ──────────────────────────────────────────────────
              TextButton(
                onPressed: () => _skip(context),
                child: const Text('Skip setup'),
              ),

              const SizedBox(height: AppSizes.md),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _skip(BuildContext context) async {
    try {
      await completeOnboarding();
      if (context.mounted) {
        context.go(AppRoutes.dashboard);
      }
    } catch (_) {
      // Onboarding completion is best-effort — navigate anyway.
      if (context.mounted) {
        SnackbarService.showError(
          context,
          'Could not save setup status. You can always set up later.',
        );
        context.go(AppRoutes.dashboard);
      }
    }
  }
}
