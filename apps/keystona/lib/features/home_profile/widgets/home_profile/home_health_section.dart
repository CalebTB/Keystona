import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../home_profile_copy.dart';
import '../shared/mono_section_label.dart';
import 'upkeep_tile.dart';

/// "HOME HEALTH · 82" with the upkeep tile (the maintenance score).
class HomeHealthSection extends StatelessWidget {
  const HomeHealthSection({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonoSectionLabel(HomeProfileCopy.healthTitle(score)),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        UpkeepTile(
          score: score,
          completed: completed,
          total: total,
          onTap: onTap,
        ),
      ],
    );
  }
}
