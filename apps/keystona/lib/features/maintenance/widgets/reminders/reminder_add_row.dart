import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_c.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../dashed_outline.dart';

/// The dashed "+ Add a reminder" row.
class ReminderAddRow extends StatelessWidget {
  const ReminderAddRow({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: label,
      child: DashedOutline(
        radius: AuroraRadius.lg,
        child: Container(
          constraints: BoxConstraints(
            minHeight: a.minControl(AuroraSizes.buttonHeight),
          ),
          alignment: Alignment.center,
          padding: a.symmetric(horizontal: AuroraSpacing.space6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add,
                size: a.of(AuroraTasksCSizes.actionGlyph),
                color: AuroraColors.ink,
              ),
              SizedBox(width: a.of(AuroraSpacing.space2)),
              Flexible(
                child: Text(
                  label,
                  style: AuroraType.h3.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
