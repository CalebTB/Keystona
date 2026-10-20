import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// Two outlined pills side by side ("All systems" and "5 appliances"), each a
/// 44 pt minimum target that grows with the text.
class ProfilePillRow extends StatelessWidget {
  const ProfilePillRow({
    super.key,
    required this.leftLabel,
    required this.onLeft,
    required this.rightLabel,
    required this.onRight,
  });

  final String leftLabel;
  final VoidCallback onLeft;
  final String rightLabel;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _Pill(label: leftLabel, onTap: onLeft)),
          SizedBox(width: a.of(AuroraSpacing.space3)),
          Expanded(child: _Pill(label: rightLabel, onTap: onRight)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: label,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: AuroraRadius.full,
          border: Border.all(
            color: AuroraColors.inkBorder,
            width: AuroraBorders.regular,
          ),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: a.minControl(AuroraSizes.minTouch)),
          child: Padding(
            padding: a.symmetric(
              horizontal: AuroraSpacing.space5,
              vertical: AuroraSpacing.space3,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AuroraType.buttonSm,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: a.of(AuroraSpacing.space1)),
                Icon(
                  Icons.chevron_right,
                  size: a.of(AuroraIconSizes.md),
                  color: AuroraColors.inkTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
