import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_button.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../task_form_copy.dart';

/// Cancel, the title and the Save task pill.
class TaskFormHeader extends StatelessWidget {
  const TaskFormHeader({
    super.key,
    required this.title,
    required this.onCancel,
    required this.onSave,
    required this.saving,
  });

  final String title;
  final VoidCallback? onCancel;

  /// Null while the form is not ready: Save looks disabled.
  final VoidCallback? onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      padding: a.symmetric(
        horizontal: AuroraSpacing.screenPadH,
        vertical: AuroraSpacing.space2,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AuroraColors.inkBorder,
            width: AuroraBorders.hairline,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: AuroraPressable(
                  onTap: onCancel,
                  semanticLabel: TaskFormCopy.cancel,
                  enforceTouchTarget: true,
                  child: Text(TaskFormCopy.cancel, style: AuroraType.cancel),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * AuroraSizes.sheetTitleFraction,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: a.of(AuroraSpacing.space3),
                ),
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AuroraType.sheetTitle,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: SaveButton(
                  label: TaskFormCopy.save,
                  compact: true,
                  loading: saving,
                  onPressed: onSave,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
