import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_c.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../appliance_copy.dart';

/// "We read 6 fields from the label": what the scan filled in, and Rescan at
/// the right edge.
class ApplianceScanBanner extends StatelessWidget {
  const ApplianceScanBanner({
    super.key,
    required this.fieldCount,
    required this.onRescan,
  });

  final int fieldCount;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.xl,
        border: Border.all(
          color: AuroraHomeCColors.bannerBorder,
          width: AuroraBorders.emphasis,
        ),
      ),
      child: Padding(
        padding: a.all(AuroraSpacing.space6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: a.of(AuroraHomeCSizes.bannerCheck),
              height: a.of(AuroraHomeCSizes.bannerCheck),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AuroraColors.lime,
              ),
              child: Icon(
                Icons.check,
                size: a.of(AuroraIconSizes.sm),
                color: AuroraColors.olive,
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space5)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ApplianceCopy.scanRead(fieldCount), style: AuroraType.h3),
                  SizedBox(height: a.of(AuroraSpacing.space1)),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: ApplianceCopy.scanBodyBefore),
                        TextSpan(
                          text: ApplianceCopy.scanBodyBlue,
                          style: AuroraType.body.copyWith(
                            color: AuroraColors.cobalt,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: ApplianceCopy.scanBodyAfter),
                      ],
                    ),
                    style: AuroraType.bodySm.copyWith(
                      color: AuroraColors.inkBody,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space3)),
            AuroraPressable(
              onTap: onRescan,
              semanticLabel: ApplianceCopy.rescan,
              enforceTouchTarget: true,
              child: Text(
                ApplianceCopy.rescan,
                style: AuroraType.buttonSm.copyWith(color: AuroraColors.coral),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
