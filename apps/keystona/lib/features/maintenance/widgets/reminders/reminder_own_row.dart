import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_c.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../reminders_copy.dart';

/// One of the person's own reminders: Edit and Delete, no switch.
class ReminderOwnRow extends StatelessWidget {
  const ReminderOwnRow({
    super.key,
    required this.name,
    required this.meta,
    required this.onEdit,
    required this.onDelete,
  });

  final String name;

  /// "Every fall · Added Sep 14".
  final String meta;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      constraints: BoxConstraints(
        minHeight: a.minControl(AuroraTasksCSizes.switchRowMinHeight),
      ),
      padding: EdgeInsets.only(
        left: a.of(AuroraSpacing.space6),
        right: a.of(AuroraSpacing.space2),
        top: a.of(AuroraSpacing.space4),
        bottom: a.of(AuroraSpacing.space4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: AuroraTasksCType.rowName),
                SizedBox(height: a.of(AuroraSpacing.space1)),
                Text(meta.toUpperCase(), style: AuroraType.meta),
              ],
            ),
          ),
          SizedBox(width: a.of(AuroraSpacing.space5)),
          AuroraPressable(
            onTap: onEdit,
            semanticLabel: RemindersCopy.editSemantics(name),
            enforceTouchTarget: true,
            child: Text(
              RemindersCopy.edit,
              style: AuroraType.buttonSm.copyWith(color: AuroraColors.cobalt),
            ),
          ),
          AuroraPressable(
            onTap: onDelete,
            semanticLabel: RemindersCopy.deleteSemantics(name),
            enforceTouchTarget: true,
            child: Icon(
              Icons.delete_outline,
              size: a.of(AuroraTasksCSizes.deleteGlyph),
              color: AuroraColors.coralDeep,
            ),
          ),
        ],
      ),
    );
  }
}
