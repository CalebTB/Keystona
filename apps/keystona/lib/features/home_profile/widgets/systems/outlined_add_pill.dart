import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// The cobalt outlined "+ Add" pill in a top bar.
class OutlinedAddPill extends StatelessWidget {
  const OutlinedAddPill({
    super.key,
    required this.label,
    required this.onTap,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: semanticLabel ?? label,
      enforceTouchTarget: true,
      child: Container(
        constraints: BoxConstraints(minHeight: a.minControl(AuroraSizes.chipHeight)),
        padding: a.symmetric(
          horizontal: AuroraSpacing.space8,
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
          child: Text(
            label,
            style: AuroraType.button.copyWith(color: AuroraColors.cobalt),
          ),
        ),
      ),
    );
  }
}
