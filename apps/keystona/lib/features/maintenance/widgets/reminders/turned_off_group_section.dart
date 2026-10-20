import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../models/reminder_groups.dart';
import '../../models/reminder_item.dart';
import '../../reminders_copy.dart';
import 'reminder_group_card.dart';
import 'reminder_group_header.dart';
import 'reminder_turn_on_row.dart';

/// One parent's turned-off reminders on the Settings safety net: its name, a
/// "See all" link, and a card of rows with Turn on at the right edge.
class TurnedOffGroupSection extends StatelessWidget {
  const TurnedOffGroupSection({
    super.key,
    required this.group,
    required this.onSeeAll,
    required this.onTurnOn,
    required this.onUndo,
  });

  final ReminderGroup group;
  final VoidCallback onSeeAll;
  final void Function(ReminderItem item) onTurnOn;
  final void Function(ReminderItem item) onUndo;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReminderGroupHeader(
          title: group.title,
          trailing: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: AuroraPressable(
              onTap: onSeeAll,
              semanticLabel: '${RemindersCopy.seeAll}: ${group.title}',
              enforceTouchTarget: true,
              child: Text(
                RemindersCopy.seeAll,
                style: AuroraType.buttonSm.copyWith(color: AuroraColors.cobalt),
              ),
            ),
          ),
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        ReminderGroupCard(
          rows: [
            for (final item in group.items)
              ReminderTurnOnRow(
                key: ValueKey(item.id),
                name: item.name,
                reason: RemindersCopy.settingsOffSince(
                  item.offSince,
                  item.offReason,
                ),
                backOn: item.enabled,
                onTurnOn: () => onTurnOn(item),
                onUndo: () => onUndo(item),
              ),
          ],
        ),
      ],
    );
  }
}
