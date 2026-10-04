import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/aurora/aurora.dart';

/// First onboarding screen. No app bar — full-bleed centered layout.
///
/// Routes:
///   "Get Started" → [AppRoutes.onboardingProperty]
///   "Sign in"     → [AppRoutes.login]
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuroraColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AuroraSpacing.screenPadH,
          ),
          child: Column(
            children: [
              const Spacer(),

              // ── Coral circle hero with yellow blob ────────────────────────
              _HeroCircle(),

              const SizedBox(height: AuroraSpacing.space8),

              // ── App name ──────────────────────────────────────────────────
              Text(
                'Keystona',
                style: AuroraType.h1,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AuroraSpacing.space2),

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
              PrimaryButton(
                label: 'Get Started',
                onPressed: () => context.go(AppRoutes.onboardingProperty),
                expand: true,
              ),

              const SizedBox(height: AuroraSpacing.space3),

              // ── Sign in ────────────────────────────────────────────────────
              GhostButton(
                label: 'Sign in',
                onPressed: () => context.go(AppRoutes.login),
              ),

              const SizedBox(height: AuroraSpacing.space7),
            ],
          ),
        ),
      ),
    );
  }
}

/// Coral circle with a yellow blob accent — one coral hero per screen.
class _HeroCircle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Yellow blob
          Positioned(
            top: 12,
            right: 14,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AuroraColors.yellow,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Coral circle
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: AuroraColors.coral,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.home_work_rounded,
              color: AuroraColors.paper,
              size: 52,
            ),
          ),
        ],
      ),
    );
  }
}
