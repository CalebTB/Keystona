import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_home_shared.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';

/// Eyebrow, the address as the title, and the facts line.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.eyebrow,
    required this.address,
    required this.facts,
  });

  final String eyebrow;
  final String address;
  final String facts;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraSpacing.space2));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow, style: AuroraType.label),
        gap,
        Semantics(
          header: true,
          child: Text(address, style: AuroraHomeType.itemTitle),
        ),
        if (facts.isNotEmpty) ...[gap, Text(facts, style: AuroraType.meta)],
      ],
    );
  }
}
