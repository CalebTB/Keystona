import 'package:flutter/material.dart';

import '../theme/aurora_colors.dart';
import '../theme/aurora_radius.dart';
import '../theme/aurora_typography.dart';

/// Status pill used to communicate status at a glance.
///
/// Font: JetBrains Mono 9px, uppercase. Radius: 4px (Aurora radius-xs).
/// Text is always uppercased internally.
///
/// For common states use the named constructors on [aurora_chip.dart]'s
/// [StatusChip]. Use [StatusBadge] when you need to pass arbitrary colors.
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
