import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_b.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_chip.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../systems_copy.dart';

/// The WARRANTY card: shield, the warranty's title and "NORTHLINE · UNTIL MAR
/// 2031", and an ACTIVE (or ENDED) chip.
class SystemWarrantyCard extends StatelessWidget {
  const SystemWarrantyCard({
    super.key,
    required this.title,
    required this.meta,
    required this.active,
    this.onTap,
  });

  final String title;
  final String meta;
  final bool active;

  /// Opens the linked warranty document; null when none is linked.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final accent = active ? AuroraColors.limeDeep : AuroraColors.inkBorderStrong;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: '$title, $meta',
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: AuroraRadius.xl,
          border: Border.all(color: accent, width: AuroraBorders.emphasis),
        ),
        child: Padding(
          padding: a.symmetric(
            horizontal: AuroraSpacing.space6,
            vertical: AuroraSpacing.space5,
          ),
          child: Row(
            children: [
              Container(
                width: a.of(AuroraHomeBSizes.warrantyDisc),
                height: a.of(AuroraHomeBSizes.warrantyDisc),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent,
                    width: AuroraBorders.emphasis,
                  ),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: a.of(AuroraHomeBSizes.warrantyGlyph),
                  color: active ? AuroraColors.limeDeep : AuroraColors.inkSecondary,
                ),
              ),
              SizedBox(width: a.of(AuroraSpacing.space5)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AuroraType.h3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: a.of(AuroraSpacing.space1)),
                    Text(
                      meta,
                      style: AuroraType.meta,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: a.of(AuroraSpacing.space3)),
              StatusChip(
                label: active
                    ? SystemsCopy.warrantyActive
                    : SystemsCopy.warrantyEnded,
                background: AuroraColors.paper,
                foreground: active
                    ? AuroraColors.oliveDeep
                    : AuroraColors.inkSecondary,
                borderColor: accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
