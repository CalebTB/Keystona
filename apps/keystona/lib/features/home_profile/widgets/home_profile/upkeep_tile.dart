import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_card.dart';
import '../../home_profile_copy.dart';
import '../../../../core/theme/aurora_home_a.dart';
import 'health_ring.dart';

/// The upkeep score: a ring, "UPKEEP" and how many tasks are done. Opens the
/// Tasks tab. Only the maintenance score exists today; the kit's Records and
/// Emergency rings wait for their data.
class UpkeepTile extends StatelessWidget {
  const UpkeepTile({
    super.key,
    required this.score,
    required this.completed,
    required this.total,
    required this.onTap,
  });

  final int score;
  final int completed;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraCard(
      onTap: onTap,
      padding: a.symmetric(
        horizontal: AuroraSpacing.space6,
        vertical: AuroraSpacing.space5,
      ),
      child: Row(
        children: [
          HealthRing(score: score),
          SizedBox(width: a.of(AuroraSpacing.space6)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(HomeProfileCopy.upkeep, style: AuroraHomeAType.caption),
                SizedBox(height: a.of(AuroraSpacing.space1)),
                Text(
                  HomeProfileCopy.upkeepMeta(completed, total),
                  style: AuroraType.meta,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
