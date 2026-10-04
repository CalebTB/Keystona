import 'package:flutter/material.dart';

import '../theme/aurora_colors.dart';
import '../theme/aurora_radius.dart';
import '../theme/aurora_spacing.dart';
import '../theme/aurora_typography.dart';
import 'aurora/aurora_button.dart';
import 'aurora/aurora_card.dart';

/// Pattern C — Icon + h3 title + body + optional CTA.
///
/// Use for standard empty lists and sections. All copy must come from the
/// Empty States Catalog to ensure consistency across the app.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  /// Icon displayed above the title text.
  final IconData icon;

  /// Primary heading text. Use sentence case.
  final String title;

  /// Secondary descriptive text below the title.
  final String subtitle;

  /// Optional label for the action button. When null the button is hidden.
  final String? actionLabel;

  /// Callback for the action button tap.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AuroraSpacing.space9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: AuroraColors.inkTertiary,
            ),
            const SizedBox(height: AuroraSpacing.space7),
            Text(
              title,
              style: AuroraType.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuroraSpacing.space3),
            Text(
              subtitle,
              style: AuroraType.body.copyWith(
                color: AuroraColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AuroraSpacing.space9),
              PrimaryButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pattern A — Motivational hero circle empty state.
///
/// Coral hero circle with icon, h1 title, body subtitle, and coral CTA.
/// Use for the first-time / zero-state of a primary feature screen.
class EmptyStateHero extends StatelessWidget {
  const EmptyStateHero({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AuroraSpacing.space9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Coral hero circle with yellow blob
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: AuroraColors.coral,
                      borderRadius: AuroraRadius.full,
                    ),
                    child: const Center(
                      child: SizedBox.shrink(),
                    ),
                  ),
                  // Yellow decorative blob
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AuroraColors.yellow.withValues(alpha: 0.32),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Centered icon
                  const Center(
                    child: SizedBox.shrink(),
                  ),
                  Center(
                    child: Icon(
                      icon,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AuroraSpacing.space8),
            Text(
              title,
              style: AuroraType.h1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AuroraSpacing.space3),
            Text(
              subtitle,
              style: AuroraType.body.copyWith(
                color: AuroraColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AuroraSpacing.space9),
              PrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pattern E — Inline CTA card.
///
/// Butter-background AuroraCard with icon tile, title, subtitle, and half-width
/// cobalt SaveButton. Use for secondary empty states within a screen that
/// already has another primary empty state or for feature upsell sections.
class EmptyStateCta extends StatelessWidget {
  const EmptyStateCta({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return AuroraCard(
      padding: const EdgeInsets.all(AuroraSpacing.space8),
      child: Container(
        decoration: const BoxDecoration(
          color: AuroraColors.butter,
          borderRadius: AuroraRadius.xl,
        ),
        padding: const EdgeInsets.all(AuroraSpacing.space8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon tile
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AuroraColors.cobaltDim,
                borderRadius: AuroraRadius.sm,
              ),
              child: Icon(
                icon,
                size: 24,
                color: AuroraColors.cobalt,
              ),
            ),
            const SizedBox(height: AuroraSpacing.space5),
            Text(
              title,
              style: AuroraType.h3,
            ),
            const SizedBox(height: AuroraSpacing.space2),
            Text(
              subtitle,
              style: AuroraType.body.copyWith(
                color: AuroraColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AuroraSpacing.space7),
            // Half-width cobalt CTA
            FractionallySizedBox(
              widthFactor: 0.5,
              child: SaveButton(
                label: actionLabel,
                onPressed: onAction,
                expand: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
