import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_c.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../reminders_copy.dart';

/// A turned-off reminder with why it is off and a Turn on pill at the right
/// edge. Once turned on the row says it is back and offers Undo instead.
class ReminderTurnOnRow extends StatelessWidget {
  const ReminderTurnOnRow({
    super.key,
    required this.name,
    required this.reason,
    required this.backOn,
    required this.onTurnOn,
    required this.onUndo,
  });

  final String name;

  /// "Off since Sep 12".
  final String reason;
  final bool backOn;
  final VoidCallback onTurnOn;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      constraints: BoxConstraints(
        minHeight: a.minControl(AuroraTasksCSizes.detailRowMinHeight),
      ),
      padding: a.symmetric(
        horizontal: AuroraSpacing.space6,
        vertical: AuroraSpacing.space4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: AuroraTasksCType.rowName.copyWith(
                    color: backOn ? AuroraColors.ink : AuroraColors.inkSubtle,
                  ),
                ),
                SizedBox(height: a.of(AuroraSpacing.space1)),
                Text(
                  (backOn ? RemindersCopy.backOn : reason).toUpperCase(),
                  style: AuroraType.meta.copyWith(
                    fontWeight: backOn ? FontWeight.w700 : FontWeight.w500,
                    color: backOn
                        ? AuroraColors.limeDeep
                        : AuroraColors.inkSubtle,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: a.of(AuroraSpacing.space5)),
          _RowPill(
            label: backOn ? RemindersCopy.undo : RemindersCopy.turnOn,
            outlined: !backOn,
            onTap: backOn ? onUndo : onTurnOn,
            semanticLabel: backOn
                ? '${RemindersCopy.undo}: $name'
                : RemindersCopy.turnOnLabel(name),
          ),
        ],
      ),
    );
  }
}

class _RowPill extends StatelessWidget {
  const _RowPill({
    required this.label,
    required this.outlined,
    required this.onTap,
    required this.semanticLabel,
  });

  final String label;
  final bool outlined;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      enforceTouchTarget: true,
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.of(AuroraSizes.buttonHeightSm),
        ),
        alignment: Alignment.center,
        padding: a.symmetric(horizontal: AuroraSpacing.pillHCompact),
        decoration: BoxDecoration(
          borderRadius: AuroraRadius.full,
          border: outlined
              ? Border.all(
                  color: AuroraColors.cobalt,
                  width: AuroraBorders.emphasis,
                )
              : null,
        ),
        child: Text(
          label,
          style: AuroraType.buttonSm.copyWith(
            color: outlined ? AuroraColors.cobalt : AuroraColors.inkSubtle,
          ),
        ),
      ),
    );
  }
}
