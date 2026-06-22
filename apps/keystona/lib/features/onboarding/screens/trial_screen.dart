import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AuroraSpacing.screenPadH),
          child: Column(
            children: [
              const Spacer(),

              // ── Title ──────────────────────────────────────────────────────
              Text(
                'Try Premium Free',
                style: AuroraType.h1,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AuroraSpacing.space3),

              // ── Subtitle ───────────────────────────────────────────────────
              Text(
                r'30 days free, then $4.99/month. Cancel anytime.',
                style: AuroraType.body.copyWith(
                  color: AuroraColors.inkSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AuroraSpacing.space10),

              // ── Benefit bullets ────────────────────────────────────────────
              _BulletRow(text: 'Unlimited document storage'),
              const SizedBox(height: AuroraSpacing.space7),
              _BulletRow(text: 'Smart maintenance reminders'),
              const SizedBox(height: AuroraSpacing.space7),
              _BulletRow(text: 'Emergency hub for your whole household'),

              const Spacer(),

              // ── Start Free Trial CTA ───────────────────────────────────────
              ElevatedButton(
                onPressed: () => _complete(context),
                child: const Text('Start Free Trial'),
              ),

              const SizedBox(height: AuroraSpacing.space3),

              // ── No thanks ─────────────────────────────────────────────────
              TextButton(
                onPressed: () => _complete(context),
                child: const Text('No thanks'),
              ),

              const SizedBox(height: AuroraSpacing.space7),
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
          size: 24,
          color: AuroraColors.limeDeep,
        ),
        const SizedBox(width: AuroraSpacing.space3),
        Expanded(
          child: Text(text, style: AuroraType.body),
        ),
      ],
    );
  }
}
