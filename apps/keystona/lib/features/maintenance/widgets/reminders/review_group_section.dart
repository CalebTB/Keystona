import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../models/review_row.dart';
import 'reminder_group_card.dart';
import 'reminder_group_header.dart';
import 'reminder_switch_row.dart';

/// A titled group on Review your reminders: the title and why it is here,
/// then a card of switch rows.
class ReviewGroupSection extends StatelessWidget {
  const ReviewGroupSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.rows,
    required this.onToggle,
  });

  final String title;
  final String subtitle;
  final List<ReviewRow> rows;
  final void Function(String key, bool on) onToggle;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReminderGroupHeader(
          title: title,
          trailing: subtitle.isEmpty ? null : ReminderHeaderNote(subtitle),
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        ReminderGroupCard(
          rows: [
            for (final row in rows)
              ReminderSwitchRow(
                key: ValueKey(row.key),
                name: row.name,
                frequency: row.frequency,
                on: row.on,
                onChanged: (on) => onToggle(row.key, on),
              ),
          ],
        ),
      ],
    );
  }
}
