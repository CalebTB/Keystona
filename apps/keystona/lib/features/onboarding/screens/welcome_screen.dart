import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../providers/onboarding_provider.dart';

/// First onboarding screen. No app bar — full-bleed centered layout.
///
/// Routes:
///   "Get Started" → [AppRoutes.onboardingProperty]
///   "Skip setup"  → marks onboarding complete then → [AppRoutes.home]
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AuroraColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AuroraSpacing.screenPadH),
          child: Column(
            children: [
              const Spacer(),

              // ── App name ──────────────────────────────────────────────────
              Text(
                'Keystona',
                style: AuroraType.displayLg,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AuroraSpacing.space3),

              // ── Tagline ───────────────────────────────────────────────────
              Text(
                'The smart way to manage your home.',
                style: AuroraType.bodyLg.copyWith(
                  color: AuroraColors.inkSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // ── Get Started CTA ───────────────────────────────────────────
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.onboardingProperty),
                child: const Text('Get Started'),
              ),

              const SizedBox(height: AuroraSpacing.space3),

              // ── Skip setup ────────────────────────────────────────────────
              TextButton(
                onPressed: () => _skip(context),
                child: const Text('Skip setup'),
              ),

              const SizedBox(height: AuroraSpacing.space7),
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
        context.go(AppRoutes.home);
      }
    } catch (_) {
      if (context.mounted) {
        SnackbarService.showError(
          context,
          'Could not save setup status. You can always set up later.',
        );
        context.go(AppRoutes.home);
      }
    }
  }
}
