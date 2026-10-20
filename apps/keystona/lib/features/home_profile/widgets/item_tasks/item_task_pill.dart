import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_c.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';

/// A small pill on a task card: outlined ("EVERY 3 MONTHS", "DIY") or solid
/// ink ("PRO").
class ItemTaskPill extends StatelessWidget {
  const ItemTaskPill({super.key, required this.label, this.solid = false});

  final String label;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: a.of(AuroraSpacing.space2),
        vertical: a.of(AuroraSpacing.space1) / 2,
      ),
      decoration: BoxDecoration(
        color: solid ? AuroraColors.ink : null,
        borderRadius: AuroraRadius.full,
        border: solid
            ? null
            : Border.all(
                color: AuroraHomeCColors.pillBorder,
                width: AuroraBorders.regular,
              ),
      ),
      child: Text(
        label.toUpperCase(),
        style: AuroraHomeCType.pill.copyWith(
          color: solid ? AuroraColors.paper : AuroraColors.inkSubtle,
        ),
      ),
    );
  }
}
