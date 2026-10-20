import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_button.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../home_edit_copy.dart';

/// Cancel at the left, the title, and a Save pill at the right. Save is grey
/// until [onSave] is given (something changed and it is valid).
class EditTopBar extends StatelessWidget {
  const EditTopBar({
    super.key,
    required this.onCancel,
    required this.onSave,
    this.saving = false,
  });

  final VoidCallback onCancel;
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
        builder: (context, box) => Row(
          children: [
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: AuroraPressable(
                  onTap: onCancel,
                  semanticLabel: HomeEditCopy.cancel,
                  enforceTouchTarget: true,
                  child: Text(HomeEditCopy.cancel, style: AuroraType.cancel),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: box.maxWidth * AuroraSizes.sheetTitleFraction,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: a.of(AuroraSpacing.space3),
                ),
                child: Semantics(
                  header: true,
                  child: Text(
                    HomeEditCopy.title,
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
                  label: HomeEditCopy.save,
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
