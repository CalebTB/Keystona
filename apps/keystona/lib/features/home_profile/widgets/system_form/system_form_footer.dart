import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_button.dart';
import '../../systems_copy.dart';

/// Cancel, the cobalt Save pill (disabled until a name is typed) and the
/// "REQUIRED * · EVERYTHING ELSE CAN WAIT" note.
class SystemFormFooter extends StatelessWidget {
  const SystemFormFooter({
    super.key,
    required this.saveLabel,
    required this.onCancel,
    required this.onSave,
    required this.saving,
  });

  final String saveLabel;
  final VoidCallback onCancel;

  /// Null disables Save (no name yet).
  final VoidCallback? onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SecondaryButton(
              label: SystemsCopy.cancel,
              onPressed: saving ? null : onCancel,
            ),
            SizedBox(width: a.of(AuroraSpacing.space4)),
            Expanded(
              child: PrimaryButton(
                label: saveLabel,
                loading: saving,
                onPressed: onSave,
                expand: true,
              ),
            ),
          ],
        ),
        SizedBox(height: a.of(AuroraSpacing.space5)),
        Text.rich(
          TextSpan(
            style: AuroraType.helper,
            children: [
              const TextSpan(text: SystemsCopy.requiredPrefix),
              TextSpan(
                text: '*',
                style: AuroraType.helper.copyWith(color: AuroraColors.coral),
              ),
              const TextSpan(text: ' · ${SystemsCopy.requiredNote}'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
