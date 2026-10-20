import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_c.dart';
import '../../models/reminder_groups.dart';
import '../../models/reminder_item.dart';
import '../../reminders_copy.dart';
import 'house_group_section.dart';
import 'reminder_info_card.dart';
import 'reminder_stat_tiles.dart';
import 'reminders_header.dart';
import 'yours_section.dart';

/// Everything under the back link on Around the house.
class HomeRemindersBody extends StatelessWidget {
  const HomeRemindersBody({
    super.key,
    required this.data,
    required this.onToggle,
    required this.onPickFrequency,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
  });

  final RemindersData data;
  final void Function(ReminderItem item, bool on) onToggle;
  final void Function(ReminderItem item) onPickFrequency;
  final void Function(ReminderItem item) onEdit;
  final void Function(ReminderItem item) onDelete;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final section = SizedBox(height: a.of(AuroraTasksCSizes.blockGap));
    final house = [
      for (final i in data.items)
        if (i.isAroundTheHouse) i,
    ];
    final on = house.where((i) => i.enabled).length;
    final mine = ReminderGroups.mine(house);
    final groups = ReminderGroups.house(house);
    final eyebrow = RemindersCopy.homeEyebrow(data.addressLine?.toUpperCase());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RemindersHeader(
          eyebrow: eyebrow,
          title: RemindersCopy.homeTitle,
          blurb: RemindersCopy.homeBlurb,
        ),
        SizedBox(height: a.of(AuroraSpacing.space8)),
        ReminderStatTiles(on: on, off: house.length - on, yours: mine.length),
        for (final group in groups) ...[
          section,
          HouseGroupSection(
            group: group,
            climateZone: data.climateZone,
            onToggle: onToggle,
            onPickFrequency: onPickFrequency,
          ),
        ],
        section,
        YoursSection(
          items: mine,
          onEdit: onEdit,
          onDelete: onDelete,
          onAdd: onAdd,
        ),
        section,
        const ReminderInfoCard(
          icon: Icons.done_all,
          text: RemindersCopy.homeHint,
          accent: true,
        ),
      ],
    );
  }
}
