import 'package:flutter/material.dart';

import '../../../../../core/theme/aurora_colors.dart';
import '../../../../../core/theme/aurora_docs_b.dart';
import '../../../../../core/theme/aurora_radius.dart';
import '../../../../../core/theme/aurora_scale.dart';
import '../../../../../core/theme/aurora_spacing.dart';
import '../../../../../core/theme/aurora_typography.dart';
import '../../../../../core/widgets/aurora/aurora_pressable.dart';

/// "Smart scan | Just the photo" segmented switch.
class CameraModeToggle extends StatelessWidget {
  const CameraModeToggle({
    super.key,
    required this.smart,
    required this.onChanged,
  });

  final bool smart;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      padding: EdgeInsets.all(a.of(AuroraCameraSizes.togglePad)),
      decoration: const BoxDecoration(
        color: AuroraCameraColors.toggleTrack,
        borderRadius: AuroraRadius.full,
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: _Segment(
                label: 'Smart scan',
                on: smart,
                onTap: () => onChanged(true),
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space1)),
            Flexible(
              child: _Segment(
                label: 'Just the photo',
                on: !smart,
                onTap: () => onChanged(false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.on, required this.onTap});

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: label,
      selected: on,
      enforceTouchTarget: true,
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.of(AuroraCameraSizes.toggleHeight),
        ),
        alignment: Alignment.center,
        padding: a.symmetric(horizontal: AuroraSpacing.space6),
        decoration: BoxDecoration(
          color: on ? AuroraColors.paper : AuroraStructure.transparent,
          borderRadius: AuroraRadius.full,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AuroraType.chip.copyWith(
            fontWeight: FontWeight.w600,
            color: on ? AuroraColors.ink : AuroraCameraColors.toggleInactive,
          ),
        ),
      ),
    );
  }
}
