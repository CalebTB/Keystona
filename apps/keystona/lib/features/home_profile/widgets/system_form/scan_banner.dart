import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_b.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../systems_copy.dart';

/// "We read 5 fields from the label": what the scan filled in, with Rescan.
class ScanBanner extends StatelessWidget {
  const ScanBanner({super.key, required this.count, required this.onRescan});

  final int count;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.xl,
        border: Border.all(
          color: AuroraColors.limeDeep,
          width: AuroraBorders.emphasis,
        ),
      ),
      child: Padding(
        padding: a.symmetric(
          horizontal: AuroraSpacing.space6,
          vertical: AuroraSpacing.space5,
        ),
        child: Row(
          children: [
            Container(
              width: a.of(AuroraHomeBSizes.bannerCheck),
              height: a.of(AuroraHomeBSizes.bannerCheck),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AuroraColors.lime,
              ),
              child: Icon(
                Icons.check,
                size: a.of(AuroraHomeBSizes.bannerCheckGlyph),
                color: AuroraColors.limeDeep,
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space5)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(SystemsCopy.bannerTitle(count), style: AuroraType.h3),
                  SizedBox(height: a.of(AuroraSpacing.space1)),
                  Text.rich(
                    TextSpan(
                      style: AuroraType.bodySm.copyWith(
                        color: AuroraColors.inkSubtle,
                      ),
                      children: [
                        const TextSpan(text: SystemsCopy.bannerBodyStart),
                        TextSpan(
                          text: SystemsCopy.bannerBlue,
                          style: AuroraType.bodySm.copyWith(
                            color: AuroraColors.cobalt,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: SystemsCopy.bannerBodyEnd),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space3)),
            AuroraPressable(
              onTap: onRescan,
              semanticLabel: SystemsCopy.rescan,
              enforceTouchTarget: true,
              child: Text(
                SystemsCopy.rescan,
                style: AuroraType.buttonSm.copyWith(
                  color: AuroraColors.coralDeep,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
