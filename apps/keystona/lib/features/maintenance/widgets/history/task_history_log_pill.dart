import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// The "+ Log a past one" pill at the top right of History: a cobalt outline
/// on paper, 36 pt drawn and a 44 pt target.
class TaskHistoryLogPill extends StatelessWidget {
  const TaskHistoryLogPill({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: 'Log a past one',
      enforceTouchTarget: true,
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.of(AuroraSizes.buttonHeightSm),
        ),
        padding: a.symmetric(
          horizontal: AuroraSpacing.pillHCompact,
          vertical: AuroraSpacing.space2,
        ),
        decoration: BoxDecoration(
          borderRadius: AuroraRadius.full,
          border: Border.all(
            color: AuroraColors.cobalt,
            width: AuroraBorders.emphasis,
          ),
        ),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Text(
            '+ Log a past one',
            style: AuroraType.buttonSm.copyWith(color: AuroraColors.cobalt),
          ),
        ),
      ),
    );
  }
}
