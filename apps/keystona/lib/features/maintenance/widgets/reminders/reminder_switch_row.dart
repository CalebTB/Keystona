import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_c.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_toggle_row.dart';
import '../../reminders_copy.dart';

/// A reminder with its frequency underneath and a switch at the right edge
/// (Review your reminders). Off reminders dim and say they won't show up.
class ReminderSwitchRow extends StatelessWidget {
  const ReminderSwitchRow({
    super.key,
    required this.name,
    required this.frequency,
    required this.on,
    required this.onChanged,
  });

  final String name;

  /// "Every 3 months".
  final String frequency;
  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      constraints: BoxConstraints(
        minHeight: a.minControl(AuroraTasksCSizes.switchRowMinHeight),
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
                    color: on ? AuroraColors.ink : AuroraColors.inkHelper,
                  ),
                ),
                SizedBox(height: a.of(AuroraSpacing.space1)),
                Text(
                  (on ? frequency : RemindersCopy.offWontShow).toUpperCase(),
                  style: AuroraType.meta.copyWith(
                    fontWeight: FontWeight.w600,
                    color: on
                        ? AuroraColors.inkSecondary
                        : AuroraColors.inkPlaceholder,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: a.of(AuroraSpacing.space5)),
          AuroraSwitch(
            value: on,
            onChanged: onChanged,
            semanticLabel: on
                ? RemindersCopy.turnOffLabel(name)
                : RemindersCopy.turnOnLabel(name),
          ),
        ],
      ),
    );
  }
}
