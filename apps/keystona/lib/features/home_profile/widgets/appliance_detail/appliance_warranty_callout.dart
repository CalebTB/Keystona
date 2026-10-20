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

/// "WARRANTY ENDS IN 66 DAYS": the amber callout shown while the warranty is
/// about to end, with the button that adds (or takes back) a one-off check
/// task before it does.
class ApplianceWarrantyCallout extends StatelessWidget {
  const ApplianceWarrantyCallout({
    super.key,
    required this.daysLeft,
    required this.endsOn,
    required this.checkDue,
    required this.onToggleCheck,
    this.busy = false,
  });

  final int daysLeft;
  final DateTime endsOn;

  /// When the added check is due; null while there is none.
  final DateTime? checkDue;
  final VoidCallback onToggleCheck;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final added = checkDue != null;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.xl,
        border: Border.all(
          color: AuroraColors.amber,
          width: AuroraBorders.emphasis,
        ),
      ),
      child: Padding(
        padding: a.all(AuroraSpacing.space6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: a.of(AuroraHomeCSizes.calloutIcon),
                  height: a.of(AuroraHomeCSizes.calloutIcon),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AuroraColors.amber,
                      width: AuroraBorders.emphasis,
                    ),
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    size: a.of(AuroraIconSizes.sm),
                    color: AuroraColors.amberDeep,
                  ),
                ),
                SizedBox(width: a.of(AuroraSpacing.space5)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ApplianceCopy.warrantyEndsIn(daysLeft).toUpperCase(),
                        style: AuroraType.labelSm.copyWith(
                          color: AuroraColors.amberDeep,
                        ),
                      ),
                      SizedBox(height: a.of(AuroraSpacing.space1)),
                      Text(
                        ApplianceCopy.coveredUntil(endsOn),
                        style: AuroraType.h3,
                      ),
                      SizedBox(height: a.of(AuroraSpacing.space2)),
                      Text(
                        ApplianceCopy.warrantyBody,
                        style: AuroraType.bodySm.copyWith(
                          color: AuroraColors.inkBody,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: a.of(AuroraSpacing.space5)),
            AuroraPressable(
              onTap: busy ? null : onToggleCheck,
              semanticLabel: added
                  ? ApplianceCopy.checkAdded(checkDue!)
                  : ApplianceCopy.addCheck(endsOn),
              child: Container(
                constraints: BoxConstraints(
                  minHeight: a.minControl(AuroraSizes.buttonHeight),
                ),
                padding: a.symmetric(horizontal: AuroraSpacing.space7),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: AuroraRadius.full,
                  border: Border.all(
                    color: AuroraColors.cobalt,
                    width: AuroraBorders.emphasis,
                  ),
                ),
                child: Text(
                  added
                      ? ApplianceCopy.checkAdded(checkDue!)
                      : ApplianceCopy.addCheck(endsOn),
                  textAlign: TextAlign.center,
                  style: AuroraType.button.copyWith(color: AuroraColors.cobalt),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
