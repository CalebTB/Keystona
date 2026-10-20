import 'package:flutter/cupertino.dart';
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

/// Step one of ScanFlow, drawn as a sheet: "What are you scanning?" with the
/// two cards, and the "add it by hand" link.
class ScanChoosePanel extends StatelessWidget {
  const ScanChoosePanel({
    super.key,
    required this.systemCount,
    required this.applianceCount,
    required this.onSystem,
    required this.onAppliance,
    required this.onByHand,
    required this.onClose,
  });

  final int? systemCount;
  final int? applianceCount;
  final VoidCallback onSystem;
  final VoidCallback onAppliance;
  final VoidCallback onByHand;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: AuroraRadius.sheetTop,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          a.of(AuroraSpacing.screenPadH),
          a.of(AuroraSpacing.space4),
          a.of(AuroraSpacing.screenPadH),
          a.of(AuroraSpacing.space10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(SystemsCopy.scanEyebrow, style: AuroraType.label),
                      SizedBox(height: a.of(AuroraSpacing.space2)),
                      Semantics(
                        header: true,
                        child: Text(
                          SystemsCopy.scanChooseTitle,
                          style: AuroraType.h2,
                        ),
                      ),
                      SizedBox(height: a.of(AuroraSpacing.space2)),
                      Text(
                        SystemsCopy.scanChooseBody,
                        style: AuroraType.body.copyWith(
                          color: AuroraColors.inkSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
                AuroraPressable(
                  onTap: onClose,
                  semanticLabel: SystemsCopy.scanClose,
                  enforceTouchTarget: true,
                  child: SizedBox.square(
                    dimension: a.minControl(AuroraSizes.minTouch),
                    child: Icon(
                      Icons.close,
                      size: a.of(AuroraIconSizes.xl),
                      color: AuroraColors.inkSecondary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: a.of(AuroraSpacing.space7)),
            _ChooseCard(
              icon: Icons.receipt_long_outlined,
              title: SystemsCopy.scanSystemTitle,
              body: SystemsCopy.scanSystemBody,
              count: systemCount,
              onTap: onSystem,
            ),
            SizedBox(height: a.of(AuroraSpacing.space4)),
            _ChooseCard(
              icon: Icons.local_laundry_service_outlined,
              title: SystemsCopy.scanApplianceTitle,
              body: SystemsCopy.scanApplianceBody,
              count: applianceCount,
              onTap: onAppliance,
            ),
            SizedBox(height: a.of(AuroraSpacing.space4)),
            AuroraPressable(
              onTap: onByHand,
              semanticLabel: SystemsCopy.scanByHand,
              enforceTouchTarget: true,
              child: Center(
                child: Text(
                  SystemsCopy.scanByHand,
                  style: AuroraType.button.copyWith(
                    color: AuroraColors.inkSubtle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChooseCard extends StatelessWidget {
  const _ChooseCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: title,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: AuroraRadius.xl,
          border: Border.all(
            color: AuroraColors.inkBorder,
            width: AuroraBorders.regular,
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
                width: a.of(AuroraHomeBSizes.chooseTile),
                height: a.of(AuroraHomeBSizes.chooseTile),
                decoration: BoxDecoration(
                  borderRadius: AuroraRadius.lg,
                  border: Border.all(
                    color: AuroraColors.inkTileBorder,
                    width: AuroraBorders.regular,
                  ),
                ),
                child: Icon(
                  icon,
                  size: a.of(AuroraHomeBSizes.chooseTileGlyph),
                  color: AuroraColors.ink,
                ),
              ),
              SizedBox(width: a.of(AuroraSpacing.space6)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AuroraType.h3),
                    SizedBox(height: a.of(AuroraSpacing.space1)),
                    Text(
                      body,
                      style: AuroraType.bodySm.copyWith(
                        color: AuroraColors.inkSubtle,
                      ),
                    ),
                    if (count != null) ...[
                      SizedBox(height: a.of(AuroraSpacing.space1)),
                      Text(
                        SystemsCopy.scanInYourHome(count!),
                        style: AuroraType.meta,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: a.of(AuroraSpacing.space3)),
              Icon(
                CupertinoIcons.chevron_right,
                size: a.of(AuroraIconSizes.md),
                color: AuroraColors.inkTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
