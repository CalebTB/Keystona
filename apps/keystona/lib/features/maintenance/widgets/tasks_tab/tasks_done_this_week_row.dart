import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// "4 tasks done this week ›": one quiet row that opens All tasks.
class TasksDoneThisWeekRow extends StatelessWidget {
  const TasksDoneThisWeekRow({
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
        child: Row(
          children: [
            Icon(
              Icons.check,
              size: a.of(AuroraIconSizes.md),
              color: AuroraColors.olive,
            ),
            SizedBox(width: a.of(AuroraSpacing.space4)),
            Expanded(
              child: Text(
                label,
                style: AuroraType.number.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: a.of(AuroraIconSizes.sm),
              color: AuroraColors.inkCheckBorder,
            ),
          ],
        ),
      ),
    );
  }
}
