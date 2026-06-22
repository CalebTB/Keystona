import 'package:flutter/material.dart';

import '../theme/aurora_colors.dart';
import '../theme/aurora_radius.dart';
import '../theme/aurora_typography.dart';

/// Configurable empty state widget used whenever a list or section has no data.
///
/// All copy (title, subtitle, action label) must come from the
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: AuroraColors.inkTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AuroraType.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AuroraType.body.copyWith(
                color: AuroraColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AuroraColors.coral),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AuroraRadius.sm,
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: AuroraType.bodyLg.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AuroraColors.coral,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
