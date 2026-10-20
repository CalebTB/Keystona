import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_shared.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';

/// "• HOME PROFILE · NEW" over the big title ("Add an appliance.").
class ApplianceFormHeader extends StatelessWidget {
  const ApplianceFormHeader({
    super.key,
    required this.eyebrow,
    required this.title,
  });

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: a.of(AuroraSizes.sectionDot),
              height: a.of(AuroraSizes.sectionDot),
              decoration: const BoxDecoration(
                color: AuroraColors.cobalt,
                borderRadius: AuroraRadius.full,
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space2)),
            Flexible(
              child: Text(eyebrow.toUpperCase(), style: AuroraType.label),
            ),
          ],
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        Semantics(
          header: true,
          child: Text(title, style: AuroraHomeType.itemTitle),
        ),
      ],
    );
  }
}
