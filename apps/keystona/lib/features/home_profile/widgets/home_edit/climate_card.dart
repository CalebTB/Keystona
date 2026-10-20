import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_a.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';

/// The locked climate card: zone and name, a note on how it is set, a lock.
/// There is nothing to tap; the zone follows the ZIP.
class ClimateCard extends StatelessWidget {
  const ClimateCard({super.key, required this.title, required this.note});

  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      padding: a.symmetric(
        horizontal: AuroraSpacing.space6,
        vertical: AuroraSpacing.space5,
      ),
      decoration: const BoxDecoration(
        color: AuroraHomeAColors.lockedFill,
        borderRadius: AuroraRadius.lg,
      ),
      child: Row(
        children: [
          Icon(
            Icons.ac_unit,
            size: a.of(AuroraHomeASizes.climateGlyph),
            color: AuroraColors.inkSubtle,
          ),
          SizedBox(width: a.of(AuroraSpacing.space5)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AuroraHomeAType.climateTitle),
                SizedBox(height: a.of(AuroraSpacing.space1)),
                Text(note, style: AuroraType.helper),
              ],
            ),
          ),
          SizedBox(width: a.of(AuroraSpacing.space5)),
          Icon(
            Icons.lock_outline,
            size: a.of(AuroraHomeASizes.climateLock),
            color: AuroraColors.inkTertiary,
          ),
        ],
      ),
    );
  }
}
