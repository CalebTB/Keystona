import 'package:flutter/material.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';





/// Empty state for the Systems list screen.
///
/// Pattern A — Motivational (Combined).
///
/// **Copy from Empty States Catalog §3.3:**
/// - Icon: simplified house with gear (120px, Deep Navy)
/// - Headline: "Add your home's systems"
/// - Subtitle: "Systems are the major components of your home — HVAC,
///   plumbing, electrical, roofing, and more. Adding them unlocks
///   personalized maintenance tasks and lifespan tracking."
/// - CTA: "+ Add First System" → opens system creation form
class SystemsEmptyState extends StatelessWidget {
  const SystemsEmptyState({super.key, required this.onAddSystem});

  /// Called when the user taps "+ Add First System".
  final VoidCallback onAddSystem;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AuroraSpacing.screenPadH),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_repair_service_outlined,
              size: 120,
              color: AuroraColors.ink.withAlpha(180),
            ),
            const SizedBox(height: AuroraSpacing.space7),
            Text(
              "Add your home's systems",
              style: AuroraType.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuroraSpacing.space3),
            Text(
              'Systems are the major components of your home — HVAC, '
              'plumbing, electrical, roofing, and more. Adding them unlocks '
              'personalized maintenance tasks and lifespan tracking.',
              style: AuroraType.body.copyWith(
                color: AuroraColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuroraSpacing.space8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AuroraColors.ink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AuroraSpacing.space7,
                  vertical: AuroraSpacing.space5,
                ),
              ),
              onPressed: onAddSystem,
              icon: const Icon(Icons.add),
              label: const Text('Add First System'),
            ),
          ],
        ),
      ),
    );
  }
}
