import 'package:flutter/material.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_sizes.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../docs_copy.dart';
import '../models/docs_expiry.dart';

/// Outlined pill showing how close a document is to expiring (kit: document
/// rows). Words always accompany the color: "9 DAYS", "45 DAYS", "TO 2035",
/// "EXPIRED".
///
/// Urgent (30 days or fewer, or expired) is coral, 31 to 90 days amber, and
/// further out neutral. Urgent and soon pills carry a clock.
///
/// The [large] variant spells it out ("EXPIRES IN 45 DAYS") for the detail
/// screen.
class ExpirationBadge extends StatelessWidget {
  const ExpirationBadge({
    super.key,
    required this.expirationDate,
    this.large = false,
  });

  final DateTime expirationDate;

  /// Renders the longer label used on detail screens.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final expiry = DocsExpiry.of(expirationDate);
    final (:border, :foreground) = _colors(expiry.tone);
    final label = DocsCopy.rowPill(expiry, long: large);
    final showClock = expiry.tone != DocsExpiryTone.far;

    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Container(
          padding: a.symmetric(
            horizontal: AuroraSpacing.space3,
            vertical: AuroraSpacing.space1,
          ),
          decoration: BoxDecoration(
            borderRadius: AuroraRadius.full,
            border: Border.all(color: border, width: AuroraBorders.regular),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showClock) ...[
                Icon(
                  Icons.schedule,
                  size: a.of(AuroraIconSizes.xs),
                  color: foreground,
                ),
                SizedBox(width: a.of(AuroraSpacing.space1)),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AuroraSharedType.pill.copyWith(
                    color: foreground,
                    fontWeight: showClock ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static ({Color border, Color foreground}) _colors(DocsExpiryTone tone) =>
      switch (tone) {
        DocsExpiryTone.urgent => (
          border: AuroraColors.coral,
          foreground: AuroraColors.coralDeep,
        ),
        DocsExpiryTone.soon => (
          border: AuroraColors.amber,
          foreground: AuroraColors.amberDeep,
        ),
        DocsExpiryTone.far => (
          border: AuroraColors.inkBorderStrong,
          foreground: AuroraColors.inkSecondary,
        ),
      };
}
