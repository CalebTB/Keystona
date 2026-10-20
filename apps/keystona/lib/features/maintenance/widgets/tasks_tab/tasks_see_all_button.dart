import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// "See all 34 tasks ›": an outlined full-width pill that opens All tasks.
class TasksSeeAllButton extends StatelessWidget {
  const TasksSeeAllButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraSizes.minTouch),
        ),
        padding: EdgeInsets.symmetric(horizontal: a.of(AuroraSpacing.space7)),
        decoration: BoxDecoration(
          borderRadius: AuroraRadius.full,
          border: Border.all(
            color: AuroraColors.inkBorder,
            width: AuroraBorders.regular,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AuroraType.buttonSm,
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space1)),
            Icon(
              Icons.chevron_right,
              size: a.of(AuroraIconSizes.sm),
              color: AuroraColors.inkPlaceholder,
            ),
          ],
        ),
      ),
    );
  }
}
