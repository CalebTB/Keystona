import 'package:flutter/material.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';





/// Empty state shown when the authenticated user has no property row yet.
///
/// This is an edge-case screen — in normal flow, onboarding creates the
/// property. It can appear if the property row was somehow deleted.
///
/// Empty States Catalog: no dedicated entry for this state; uses the
/// generic Instructional (C) pattern.
class HomeProfileEmptyState extends StatelessWidget {
  const HomeProfileEmptyState({super.key, this.onSetup});

  /// Optional callback to launch the property setup flow.
  final VoidCallback? onSetup;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AuroraSpacing.screenPadH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.home_outlined,
              size: 72,
              color: AuroraColors.inkSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AuroraSpacing.space5),
            Text(
              'Set up your home profile',
              style: AuroraType.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuroraSpacing.space3),
            Text(
              'Your home profile stores key details about your property — '
              'systems, appliances, and more. Complete onboarding to get started.',
              style: AuroraType.body.copyWith(
                color: AuroraColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onSetup != null) ...[
              const SizedBox(height: AuroraSpacing.space7),
              FilledButton(
                onPressed: onSetup,
                child: const Text('Set Up Property'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
