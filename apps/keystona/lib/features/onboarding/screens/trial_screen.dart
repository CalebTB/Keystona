import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/aurora/aurora.dart';
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
      backgroundColor: AuroraColors.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AuroraSpacing.screenPadH,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AuroraSpacing.space10),

              // ── Coral hero section with yellow blob ───────────────────────
              _TrialHero(),

              const SizedBox(height: AuroraSpacing.space10),

              // ── Section eyebrow ───────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AuroraColors.cobalt,
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'WHAT YOU GET',
                    style: AuroraType.label.copyWith(
                      color: AuroraColors.inkSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AuroraSpacing.space5),

              // ── Feature tiles with lime bg ────────────────────────────────
              _FeatureTile(
                icon: Icons.folder_open_rounded,
                text: 'Unlimited document storage',
              ),
              const SizedBox(height: AuroraSpacing.space3),
              _FeatureTile(
                icon: Icons.event_repeat_rounded,
                text: 'Smart maintenance reminders',
              ),
              const SizedBox(height: AuroraSpacing.space3),
              _FeatureTile(
                icon: Icons.emergency_rounded,
                text: 'Emergency hub for your whole household',
              ),
              const SizedBox(height: AuroraSpacing.space3),
              _FeatureTile(
                icon: Icons.favorite_rounded,
                text: 'Home health score tracking',
              ),

              const SizedBox(height: AuroraSpacing.space10),

              // ── Start Free Trial CTA — coral PrimaryButton ────────────────
              PrimaryButton(
                label: 'Start Free Trial',
                onPressed: () => _complete(context),
                expand: true,
              ),

              const SizedBox(height: AuroraSpacing.space3),

              // ── No thanks ─────────────────────────────────────────────────
              Center(
                child: GhostButton(
                  label: 'No thanks',
                  onPressed: () => _complete(context),
                ),
              ),

              const SizedBox(height: AuroraSpacing.space3),

              // ── Legal fine print ──────────────────────────────────────────
              Text(
                r'30 days free, then $4.99/month. Cancel anytime.',
                style: AuroraType.labelSm.copyWith(
                  color: AuroraColors.inkTertiary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AuroraSpacing.space10),
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
      if (context.mounted) {
        SnackbarService.showError(
          context,
          'Could not save setup status. You can always set up later.',
        );
      }
    } finally {
      if (context.mounted) {
        context.go(AppRoutes.home);
      }
    }
  }
}

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _TrialHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AuroraSpacing.space9),
      decoration: const BoxDecoration(
        color: AuroraColors.coral,
        borderRadius: AuroraRadius.xxl,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Yellow blob decoration
          Positioned(
            top: -10,
            right: -10,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AuroraColors.yellow,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.home_work_rounded,
                color: Colors.white,
                size: 36,
              ),
              const SizedBox(height: AuroraSpacing.space5),
              Text(
                'Try Premium Free',
                style: AuroraType.h1.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AuroraSpacing.space2),
              Text(
                'Everything you need to manage your home,\nunlocked for 30 days.',
                style: AuroraType.body.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Feature tile ─────────────────────────────────────────────────────────────

/// Lime-background tile with icon + text — completion / success aesthetic.
class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.space7,
        vertical: AuroraSpacing.space5,
      ),
      decoration: BoxDecoration(
        color: AuroraColors.limeDim,
        borderRadius: AuroraRadius.lg,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AuroraColors.lime,
              borderRadius: AuroraRadius.sm,
            ),
            child: Icon(Icons.check_rounded, size: 18, color: AuroraColors.limeDeep),
          ),
          const SizedBox(width: AuroraSpacing.space5),
          Expanded(
            child: Text(text, style: AuroraType.body),
          ),
        ],
      ),
    );
  }
}
