import 'package:flutter/material.dart';

import '../../theme/aurora_colors.dart';
import '../../theme/aurora_motion.dart';
import '../../theme/aurora_radius.dart';
import '../../theme/aurora_scale.dart';
import '../../theme/aurora_shadows.dart';
import '../../theme/aurora_sizes.dart';
import '../../theme/aurora_spacing.dart';
import '../../theme/aurora_typography.dart';
import 'aurora_pressable.dart';

/// Aurora switch — 51x31 track, 27 knob, cobalt when on, ink 16% when off.
class AuroraSwitch extends StatelessWidget {
  const AuroraSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final changed = onChanged;
    return Semantics(
      toggled: value,
      label: semanticLabel,
      child: AuroraPressable(
        onTap: changed == null ? null : () => changed(!value),
        enforceTouchTarget: true,
        child: AnimatedContainer(
          duration: AuroraDurations.switchToggle,
          width: a.of(AuroraSizes.switchWidth),
          height: a.of(AuroraSizes.switchHeight),
          padding: EdgeInsets.all(a.of(AuroraSizes.switchInset)),
          decoration: BoxDecoration(
            color: value ? AuroraColors.cobalt : AuroraColors.inkTrackOff,
            borderRadius: AuroraRadius.full,
          ),
          child: AnimatedAlign(
            duration: AuroraDurations.switchToggle,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: a.of(AuroraSizes.switchKnob),
              height: a.of(AuroraSizes.switchKnob),
              decoration: BoxDecoration(
                color: AuroraColors.paper,
                shape: BoxShape.circle,
                boxShadow: AuroraShadows.knob,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Switch row — paper with a 1 pt ink 12% border (no tinted fill): label and
/// optional uppercase helper on the left, [AuroraSwitch] on the right.
class AuroraToggleRow extends StatelessWidget {
  const AuroraToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.helperText,
  });

  final String label;

  /// Rendered uppercase below the label.
  final String? helperText;

  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      constraints: BoxConstraints(minHeight: a.minControl(AuroraSizes.minTouch)),
      padding: a.symmetric(
        horizontal: AuroraSpacing.space6,
        vertical: AuroraSpacing.space5,
      ),
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: AuroraRadius.xl,
        border: Border.all(
          color: AuroraColors.inkBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: AuroraType.h3),
                if (helperText != null) ...[
                  SizedBox(height: a.of(AuroraSpacing.space1)),
                  Text(helperText!.toUpperCase(), style: AuroraType.helper),
                ],
              ],
            ),
          ),
          SizedBox(width: a.of(AuroraSpacing.space5)),
          AuroraSwitch(value: value, onChanged: onChanged, semanticLabel: label),
        ],
      ),
    );
  }
}
