import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_c.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_toggle_row.dart';
import '../../reminders_copy.dart';
import 'frequency_pill.dart';

/// A reminder on Around the house: its name, a how-often pill (or why it is
/// off) and a switch at the right edge.
class ReminderFrequencyRow extends StatelessWidget {
  const ReminderFrequencyRow({
    super.key,
    required this.name,
    required this.frequency,
    required this.on,
    required this.offReason,
    required this.onChanged,
    required this.onPickFrequency,
    this.tags = const [],
  });

  final String name;
  final String frequency;
  final bool on;

  /// "Off since Aug 30 · You turned it off", or the reason it was turned off.
  final String offReason;
  final ValueChanged<bool> onChanged;
  final VoidCallback onPickFrequency;

  /// Why a climate reminder is here ("FREEZE", "HUMID"); empty for most rows.
  final List<String> tags;

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
                    color: on ? AuroraColors.ink : AuroraColors.inkHelper,
                  ),
                ),
                SizedBox(height: a.of(AuroraSpacing.space2)),
                if (on)
                  Wrap(
                    spacing: a.of(AuroraSpacing.space2),
                    runSpacing: a.of(AuroraSpacing.space2),
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FrequencyPill(label: frequency, onTap: onPickFrequency),
                      for (final tag in tags) _ReasonTag(tag),
                    ],
                  )
                else
                  Text(
                    offReason.toUpperCase(),
                    style: AuroraType.meta.copyWith(
                      color: AuroraColors.inkSubtle,
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

class _ReasonTag extends StatelessWidget {
  const _ReasonTag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: a.of(AuroraTasksCSizes.tagPadH),
        vertical: a.of(AuroraTasksCSizes.tagPadV),
      ),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.full,
        border: Border.all(
          color: AuroraColors.inkInputBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Text(text.toUpperCase(), style: AuroraTasksCType.tag),
    );
  }
}
