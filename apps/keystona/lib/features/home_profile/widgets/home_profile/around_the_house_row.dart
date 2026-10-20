import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_a.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_card.dart';
import '../../home_profile_copy.dart';

/// "Around the house": the reminders that belong to the home as a whole.
/// Opens the reminders screen. [meta] is null until the reminders load.
class AroundTheHouseRow extends StatelessWidget {
  const AroundTheHouseRow({super.key, required this.onTap, this.meta});

  final VoidCallback onTap;
  final String? meta;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: a.minControl(AuroraHomeASizes.linkRowMin),
      ),
      child: AuroraCard(
        onTap: onTap,
        padding: a.symmetric(
          horizontal: AuroraSpacing.space6,
          vertical: AuroraSpacing.space4,
        ),
        child: Row(
          children: [
            Icon(
              Icons.home_outlined,
              size: a.of(AuroraIconSizes.xl),
              color: AuroraColors.ink,
            ),
            SizedBox(width: a.of(AuroraSpacing.space5)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    HomeProfileCopy.aroundTitle,
                    style: AuroraType.h3.copyWith(letterSpacing: 0),
                  ),
                  if (meta != null) ...[
                    SizedBox(height: a.of(AuroraSpacing.space1)),
                    Text(meta!, style: AuroraType.meta),
                  ],
                ],
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space3)),
            Icon(
              Icons.chevron_right,
              size: a.of(AuroraIconSizes.md),
              color: AuroraColors.inkTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
