import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_button.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// Download and Replace file side by side, with Delete document beneath.
class DocumentDetailActions extends StatelessWidget {
  const DocumentDetailActions({
    super.key,
    required this.onDownload,
    required this.onReplace,
    required this.onDelete,
  });

  final VoidCallback onDownload;
  final VoidCallback onReplace;

  /// Null while a delete is already in flight.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'Download',
                expand: true,
                onPressed: onDownload,
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space3)),
            Expanded(
              child: SecondaryButton(
                label: 'Replace file',
                expand: true,
                onPressed: onReplace,
              ),
            ),
          ],
        ),
        SizedBox(height: a.of(AuroraSpacing.space7)),
        Center(
          child: AuroraPressable(
            onTap: onDelete,
            semanticLabel: 'Delete document',
            enforceTouchTarget: true,
            child: Padding(
              padding: a.symmetric(horizontal: AuroraSpacing.space7),
              child: Text(
                'Delete document',
                style: AuroraType.buttonSm.copyWith(
                  color: onDelete == null
                      ? AuroraColors.inkPlaceholder
                      : AuroraColors.coralDeep,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
