import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../models/reminder_frequency.dart';
import '../../models/reminder_groups.dart';
import '../../models/reminder_item.dart';
import '../../reminders_copy.dart';
import 'reminder_frequency_row.dart';
import 'reminder_group_card.dart';
import 'reminder_group_header.dart';

/// One group on Around the house (Safety, Outside, Yard, From your climate):
/// the title with "3 OF 4 ON", then a card of reminders with a how-often pill
/// and a switch each.
class HouseGroupSection extends StatelessWidget {
  const HouseGroupSection({
    super.key,
    required this.group,
    required this.climateZone,
    required this.onToggle,
    required this.onPickFrequency,
  });

  final ReminderGroup group;
  final int? climateZone;
  final void Function(ReminderItem item, bool on) onToggle;
  final void Function(ReminderItem item) onPickFrequency;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final title = group.kind == ReminderGroupKind.climate
        ? RemindersCopy.climateTitle(climateZone)
        : group.title;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReminderGroupHeader(
          title: title,
          trailing: ReminderHeaderNote(group.countLabel),
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        ReminderGroupCard(
          rows: [
            for (final item in group.items)
              ReminderFrequencyRow(
                key: ValueKey(item.id),
                name: item.name,
                frequency: ReminderFrequency.label(
                  item.recurrence,
                  intervalYears: item.intervalYears,
                ),
                on: item.enabled,
                offReason: RemindersCopy.offSince(
                  item.offSince,
                  item.offReason,
                ),
                tags: item.tags,
                onChanged: (on) => onToggle(item, on),
                onPickFrequency: () => onPickFrequency(item),
              ),
          ],
        ),
      ],
    );
  }
}
