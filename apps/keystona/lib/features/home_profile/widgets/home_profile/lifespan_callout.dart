import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_a.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// The "Water heater is at the end of its life" card: an outline in [accent]
/// (amber at the end of life, coral once past), the item's icon, a title and a
/// one-line budget. No fill.
class LifespanCallout extends StatelessWidget {
  const LifespanCallout({
    super.key,
    required this.icon,
    required this.title,
    required this.sub,
    required this.accent,
    required this.subColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String sub;
  final Color accent;
  final Color subColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: '$title. $sub',
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: AuroraRadius.xl,
          border: Border.all(color: accent, width: AuroraBorders.emphasis),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: a.minControl(AuroraHomeASizes.linkRowMin),
          ),
          child: Padding(
            padding: a.symmetric(
              horizontal: AuroraSpacing.space6,
              vertical: AuroraSpacing.space5,
            ),
            child: Row(
              children: [
                Container(
                  width: a.of(AuroraHomeASizes.calloutTile),
                  height: a.of(AuroraHomeASizes.calloutTile),
                  decoration: BoxDecoration(
                    borderRadius: AuroraRadius.tile,
                    border: Border.all(
                      color: accent,
                      width: AuroraBorders.regular,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: a.of(AuroraHomeASizes.calloutGlyph),
                    color: AuroraColors.ink,
                  ),
                ),
                SizedBox(width: a.of(AuroraSpacing.space5)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AuroraType.h3.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(height: a.of(AuroraSpacing.space1)),
                      Text(
                        sub,
                        style: AuroraType.rowDate.copyWith(color: subColor),
                      ),
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
        ),
      ),
    );
  }
}
