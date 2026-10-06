import 'package:flutter/material.dart';

import '../theme/aurora_colors.dart';
import '../theme/aurora_radius.dart';
import '../theme/aurora_scale.dart';
import '../theme/aurora_sizes.dart';
import '../theme/aurora_spacing.dart';
import '../theme/aurora_typography.dart';

/// Status pill used to communicate status at a glance (kit: ProjectStatus,
/// DocStatus).
///
/// Kit spec: outlined 999 pill, 9 px / 700 uppercase label, status-colored
/// stroke with deep text and no fill. The one filled pill is "done": solid
/// lime with olive text and a check. Words always accompany the color
/// ("$620 OVER", "3 DAYS BEHIND", "SAVED $220").
///
/// Use the named constructors for the common states.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.textColor,
    this.filled = false,
    this.showCheck = false,
  });

  final String label;

  /// Stroke color; the fill color when [filled].
  final Color color;

  /// Text color — defaults to [AuroraColors.ink] when null.
  final Color? textColor;

  /// Solid fill instead of an outline (done / win only).
  final bool filled;

  /// Leading check mark (done / win).
  final bool showCheck;

  // ── Named constructors for common statuses ──────────────────────────────

  /// On track / active / scheduled — cobalt stroke, deep cobalt text.
  factory StatusBadge.active(String label) => StatusBadge(
        label: label,
        color: AuroraColors.cobalt,
        textColor: AuroraColors.cobaltDeep,
      );

  /// Done / win — solid lime, olive text, check.
  factory StatusBadge.success(String label) => StatusBadge(
        label: label,
        color: AuroraColors.lime,
        textColor: AuroraColors.olive,
        filled: true,
        showCheck: true,
      );

  /// Over / behind / overdue — coral stroke, deep coral text.
  factory StatusBadge.overdue(String label) => StatusBadge(
        label: label,
        color: AuroraColors.coral,
        textColor: AuroraColors.coralDeep,
      );

  /// Soon / getting close — amber stroke, deep amber text.
  factory StatusBadge.warning(String label) => StatusBadge(
        label: label,
        color: AuroraColors.amber,
        textColor: AuroraColors.amberDeep,
      );

  /// Neutral / muted — hairline stroke, secondary ink text.
  factory StatusBadge.neutral(String label) => StatusBadge(
        label: label,
        color: AuroraColors.inkBorderStrong,
        textColor: AuroraColors.inkSecondary,
      );

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final fg = textColor ?? AuroraColors.ink;
    final strong = filled || color != AuroraColors.inkBorderStrong;
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: a.of(AuroraSpacing.space3),
            vertical: a.of(AuroraSpacing.space1) * _vFactor,
          ),
          decoration: BoxDecoration(
            color: filled ? color : null,
            borderRadius: AuroraRadius.full,
            border: filled
                ? null
                : Border.all(color: color, width: AuroraBorders.regular),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showCheck) ...[
                Icon(
                  Icons.check_rounded,
                  size: a.of(AuroraSharedSizes.pillCheck),
                  color: fg,
                ),
                SizedBox(width: a.of(AuroraSpacing.space1)),
              ],
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AuroraSharedType.pill.copyWith(
                    color: fg,
                    fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Kit vertical padding is 3 px (0.75 of the 4 px step).
  static const double _vFactor = 0.75;
}
