import 'package:flutter/material.dart';

import '../theme/aurora_colors.dart';
import '../theme/aurora_radius.dart';
import '../theme/aurora_typography.dart';

/// Status pill used to communicate status at a glance.
///
/// Aurora spec: AuroraRadius.xs (4px), JetBrains Mono labelSm 9px,
/// always uppercase internally. For common predefined states, use the
/// named constructors below. Pass arbitrary colors for custom states.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.textColor,
  });

  final String label;
  final Color color;

  /// Text color — defaults to [AuroraColors.ink] when null.
  final Color? textColor;

  // ── Named constructors for common statuses ──────────────────────────────

  /// Active / pending — cobaltDim background, cobalt text.
  factory StatusBadge.active(String label) => StatusBadge(
        label: label,
        color: AuroraColors.cobaltDim,
        textColor: AuroraColors.cobaltDeep,
      );

  /// Success / done / completed — limeDim background, limeDeep text.
  factory StatusBadge.success(String label) => StatusBadge(
        label: label,
        color: AuroraColors.limeDim,
        textColor: AuroraColors.limeDeep,
      );

  /// Overdue / error / urgent — coralDim background, coralDeep text.
  factory StatusBadge.overdue(String label) => StatusBadge(
        label: label,
        color: AuroraColors.coralDim,
        textColor: AuroraColors.coralDeep,
      );

  /// Warning / due-soon — yellowDim background, yellowDeep text.
  factory StatusBadge.warning(String label) => StatusBadge(
        label: label,
        color: AuroraColors.yellowDim,
        textColor: AuroraColors.yellowDeep,
      );

  /// Neutral / muted — inkBorder background, inkSecondary text.
  factory StatusBadge.neutral(String label) => StatusBadge(
        label: label,
        color: AuroraColors.inkBorder,
        textColor: AuroraColors.inkSecondary,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AuroraRadius.xs,
      ),
      child: Text(
        label.toUpperCase(),
        style: AuroraType.labelSm.copyWith(
          color: textColor ?? AuroraColors.ink,
        ),
      ),
    );
  }
}
