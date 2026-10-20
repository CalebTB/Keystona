import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import 'dashed_border.dart';

/// "+ Plumbing": a dashed pill that suggests something not tracked yet. Lay
/// them out in a `Wrap`.
class DashedSuggestionChip extends StatelessWidget {
  const DashedSuggestionChip({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: 'Add $label',
      enforceTouchTarget: true,
      child: DashedBorder(
        borderRadius: AuroraRadius.full,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: a.of(AuroraSizes.chipHeight)),
          child: Padding(
            padding: a.symmetric(
              horizontal: AuroraSpacing.space5,
              vertical: AuroraSpacing.space2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add,
                  size: a.of(AuroraIconSizes.xs),
                  color: AuroraColors.inkBody,
                ),
                SizedBox(width: a.of(AuroraSpacing.space1)),
                Flexible(
                  child: Text(
                    label,
                    style: AuroraType.chip.copyWith(color: AuroraColors.inkBody),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
