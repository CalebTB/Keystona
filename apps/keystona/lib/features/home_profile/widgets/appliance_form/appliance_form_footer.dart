import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_button.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../appliance_copy.dart';

/// Cancel and Save side by side, the "REQUIRED *" note, and (when editing) the
/// quiet coral "Delete this appliance".
class ApplianceFormFooter extends StatelessWidget {
  const ApplianceFormFooter({
    super.key,
    required this.saveLabel,
    required this.onCancel,
    required this.onSave,
    required this.saving,
    this.onDelete,
  });

  final String saveLabel;
  final VoidCallback onCancel;

  /// Null while there is no name yet.
  final VoidCallback? onSave;
  final bool saving;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Flexible(
              child: SecondaryButton(
                label: ApplianceCopy.cancel,
                onPressed: saving ? null : onCancel,
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space5)),
            Expanded(
              child: SaveButton(
                label: saveLabel,
                onPressed: onSave,
                loading: saving,
                expand: true,
              ),
            ),
          ],
        ),
        SizedBox(height: a.of(AuroraSpacing.space5)),
        Text(
          ApplianceCopy.requiredNote,
          textAlign: TextAlign.center,
          style: AuroraType.meta.copyWith(color: AuroraColors.inkHelper),
        ),
        if (onDelete != null) ...[
          SizedBox(height: a.of(AuroraSpacing.space5)),
          AuroraPressable(
            onTap: saving ? null : onDelete,
            semanticLabel: ApplianceCopy.delete,
            enforceTouchTarget: true,
            child: Center(
              child: Text(
                ApplianceCopy.delete,
                style: AuroraType.button.copyWith(color: AuroraColors.coralDeep),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
