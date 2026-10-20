import 'package:flutter/material.dart';

import '../../../../../core/theme/aurora_colors.dart';
import '../../../../../core/theme/aurora_radius.dart';
import '../../../../../core/theme/aurora_scale.dart';
import '../../../../../core/theme/aurora_sizes.dart';
import '../../../../../core/theme/aurora_spacing.dart';
import '../../../../../core/theme/aurora_tasks_a.dart';
import '../../../../../core/theme/aurora_typography.dart';
import '../../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../../tasks_copy.dart';
import '../../dashed_outline.dart';

/// "Add photos, a receipt or more": a dashed row that opens the full log.
class QuickDoneAddMore extends StatelessWidget {
  const QuickDoneAddMore({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: TasksCopy.addMore,
      child: DashedOutline(
        radius: AuroraRadius.lg,
        child: Container(
          constraints: BoxConstraints(
            minHeight: a.minControl(AuroraSizes.minTouch),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: a.of(AuroraSpacing.space6),
            vertical: a.of(AuroraSpacing.space5),
          ),
          child: Row(
            children: [
              Icon(
                Icons.photo_camera_outlined,
                size: a.of(AuroraTasksA.addMoreGlyph),
                color: AuroraColors.cobalt,
              ),
              SizedBox(width: a.of(AuroraSpacing.space5)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TasksCopy.addMore,
                      style: AuroraType.button.copyWith(
                        color: AuroraColors.cobalt,
                      ),
                    ),
                    SizedBox(height: a.of(AuroraSpacing.space1)),
                    Text(TasksCopy.addMoreSub, style: AuroraType.meta),
                  ],
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
      ),
    );
  }
}
