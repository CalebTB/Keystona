import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_home_shared.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';

/// Eyebrow over the big screen title: "APPLIANCES · 5 TRACKED" over
/// "Appliances".
class ItemHeader extends StatelessWidget {
  const ItemHeader({super.key, required this.eyebrow, required this.title});

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow.toUpperCase(), style: AuroraType.label),
        SizedBox(height: a.of(AuroraSpacing.space2)),
        Semantics(
          header: true,
          child: Text(title, style: AuroraHomeType.itemTitle),
        ),
      ],
    );
  }
}
