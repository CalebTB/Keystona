import 'package:flutter/material.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';

/// Color-coded pill badge showing document expiration status.
///
/// Thresholds:
///   - Already expired or < 30 days → Red
///   - 30–90 days → Amber
///   - > 90 days or no expiration → Green
///
/// The [large] variant shows a full label (e.g. "Expires in 45 days") suitable
/// for the detail screen metadata section. The compact variant (default) shows
/// a short label (e.g. "45d" or "Expired") for list cards.
class ExpirationBadge extends StatelessWidget {
  const ExpirationBadge({
    super.key,
    required this.expirationDate,
    this.large = false,
  });

  final DateTime expirationDate;

  /// When true, renders a wider badge with a longer label for detail screens.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final daysRemaining = expirationDate.difference(DateTime.now()).inDays;

    final Color bgColor;
    final Color textColor;
    final String label;

    if (daysRemaining < 0) {
      bgColor = AuroraColors.coralDim;
      textColor = AuroraColors.coralDeep;
      label = 'EXPIRED';
    } else if (daysRemaining < 30) {
      bgColor = AuroraColors.coralDim;
      textColor = AuroraColors.coralDeep;
      label = large ? 'EXPIRES IN ${daysRemaining}D' : '${daysRemaining}D';
    } else if (daysRemaining <= 90) {
      bgColor = AuroraColors.yellowDim;
      textColor = AuroraColors.yellowDeep;
      label = large ? 'EXPIRES IN ${daysRemaining}D' : '${daysRemaining}D';
    } else {
      bgColor = AuroraColors.limeDim;
      textColor = AuroraColors.limeDeep;
      label = large ? 'EXPIRES IN ${daysRemaining}D' : '${daysRemaining}D';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? AuroraSpacing.space5 : AuroraSpacing.space3,
        vertical: large ? AuroraSpacing.space1 : 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AuroraRadius.full,
      ),
      child: Text(
        label,
        style: (large ? AuroraType.label : AuroraType.labelSm).copyWith(
          color: textColor,
        ),
      ),
    );
  }
}
