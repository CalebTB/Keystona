import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_shared.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import 'dashed_border.dart';

/// Full-width dashed button with an icon: "Log a repair or service",
/// "Scan a label to add one", "Add a furnace task".
class DashedActionButton extends StatelessWidget {
  const DashedActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: label,
      child: DashedBorder(
        borderRadius: AuroraRadius.lg,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: a.minControl(AuroraHomeSizes.dashedButtonMin),
          ),
          child: Padding(
            padding: a.symmetric(
              horizontal: AuroraSpacing.space6,
              vertical: AuroraSpacing.space3,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: a.of(AuroraIconSizes.lg),
                  color: AuroraColors.ink,
                ),
                SizedBox(width: a.of(AuroraSpacing.space2)),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AuroraType.button,
                    maxLines: 2,
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
