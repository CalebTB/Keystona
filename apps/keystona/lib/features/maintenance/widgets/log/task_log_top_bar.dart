import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_button.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// "Cancel | Log the details | Save": Cancel at the left edge, the Save pill
/// at the right edge, the title centered between them. The title is capped so
/// both sides always keep their room.
class TaskLogTopBar extends StatelessWidget {
  const TaskLogTopBar({
    super.key,
    required this.onCancel,
    required this.onSave,
    this.saving = false,
  });

  final VoidCallback onCancel;

  /// Null disables Save (the date is not valid yet).
  final VoidCallback? onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AuroraColors.inkBorder,
            width: AuroraBorders.hairline,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          a.of(AuroraSpacing.screenPadH),
          a.of(AuroraSpacing.space2),
          a.of(AuroraSpacing.screenPadH),
          a.of(AuroraSpacing.space4),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AuroraPressable(
                    onTap: saving ? null : onCancel,
                    semanticLabel: 'Cancel',
                    enforceTouchTarget: true,
                    child: Text('Cancel', style: AuroraType.cancel),
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      constraints.maxWidth * AuroraSizes.sheetTitleFraction,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: a.of(AuroraSpacing.space3),
                  ),
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Log the details',
                      style: AuroraType.sheetTitle,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: SaveButton(
                    label: 'Save',
                    compact: true,
                    loading: saving,
                    onPressed: onSave,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
