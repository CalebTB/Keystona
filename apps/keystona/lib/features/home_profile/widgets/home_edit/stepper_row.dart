import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_a.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// A labeled value with a minus and a plus: "BEDROOMS  -  4  +". The buttons
/// are 44 pt targets. [value] reads a dash when null.
class StepperRow extends StatelessWidget {
  const StepperRow({
    super.key,
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String? value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: a.minControl(AuroraHomeASizes.stepperRowMin),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: a.of(AuroraSpacing.space6),
          right: a.of(AuroraSpacing.space2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label.toUpperCase(), style: AuroraType.label),
            ),
            _Button(
              icon: Icons.remove,
              semanticLabel: 'Fewer ${label.toLowerCase()}',
              onTap: onMinus,
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: a.of(AuroraHomeASizes.stepperValueMin),
              ),
              child: Text(
                value ?? '—',
                textAlign: TextAlign.center,
                style: AuroraHomeAType.stepperValue,
              ),
            ),
            _Button(
              icon: Icons.add,
              semanticLabel: 'More ${label.toLowerCase()}',
              onTap: onPlus,
            ),
          ],
        ),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      enforceTouchTarget: true,
      child: Icon(
        icon,
        size: a.of(AuroraIconSizes.md),
        color: AuroraColors.inkBody,
      ),
    );
  }
}
