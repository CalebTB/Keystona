import 'package:flutter/cupertino.dart';

import '../../theme/aurora_colors.dart';
import '../../theme/aurora_radius.dart';
import '../../theme/aurora_spacing.dart';
import '../../theme/aurora_typography.dart';

/// Butter-background toggle row with label and optional helper text.
///
/// Uses [CupertinoSwitch] with coral active color on all platforms.
class AuroraToggleRow extends StatelessWidget {
  const AuroraToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.helperText,
  });

  final String label;

  /// Rendered uppercase below the label in labelSm / inkTertiary.
  final String? helperText;

  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.space7,
        vertical: 14,
      ),
      decoration: const BoxDecoration(
        color: AuroraColors.butter,
        borderRadius: AuroraRadius.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: helperText != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: AuroraType.h3),
                      const SizedBox(height: AuroraSpacing.space1),
                      Text(
                        helperText!.toUpperCase(),
                        style: AuroraType.labelSm.copyWith(
                          color: AuroraColors.inkTertiary,
                        ),
                      ),
                    ],
                  )
                : Text(label, style: AuroraType.h3),
          ),
          const SizedBox(width: AuroraSpacing.space5),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AuroraColors.coral,
          ),
        ],
      ),
    );
  }
}
