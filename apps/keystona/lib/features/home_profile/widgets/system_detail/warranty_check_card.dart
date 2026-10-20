import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_button.dart';
import '../../systems_copy.dart';

/// "WARRANTY ENDS IN 66 DAYS": an amber outlined callout with the button that
/// adds a check to Tasks before the warranty ends. After it is added the
/// button reads "Added to Tasks · Nov 25" and a second tap takes it back.
class WarrantyCheckCard extends StatelessWidget {
  const WarrantyCheckCard({
    super.key,
    required this.daysLeft,
    required this.ends,
    required this.addedDue,
    required this.busy,
    required this.onToggle,
  });

  final int daysLeft;
  final DateTime ends;

  /// Due date of the added task, null while there is none.
  final DateTime? addedDue;
  final bool busy;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final added = addedDue != null;
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
        padding: a.all(AuroraSpacing.space7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              SystemsCopy.warrantyCheckTitle(daysLeft),
              style: AuroraType.label.copyWith(color: AuroraColors.amberDeep),
            ),
            SizedBox(height: a.of(AuroraSpacing.space3)),
            Text(
              SystemsCopy.warrantyCheckBody(ends),
              style: AuroraType.body.copyWith(color: AuroraColors.inkBody),
            ),
            SizedBox(height: a.of(AuroraSpacing.space6)),
            if (added)
              SecondaryButton(
                label: SystemsCopy.warrantyCheckAdded(addedDue!),
                onPressed: busy ? null : onToggle,
                expand: true,
              )
            else
              PrimaryButton(
                label: SystemsCopy.warrantyCheckAdd(ends),
                onPressed: busy ? null : onToggle,
                expand: true,
              ),
          ],
        ),
      ),
    );
  }
}
