import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_c.dart';

/// An outlined note with an icon: how reminders move when an item is added,
/// or that turned-off reminders belong to this house.
class ReminderInfoCard extends StatelessWidget {
  const ReminderInfoCard({
    super.key,
    required this.icon,
    required this.text,
    this.accent = false,
  });

  final IconData icon;
  final String text;

  /// Cobalt outline and icon instead of the neutral ones.
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      padding: a.symmetric(
        horizontal: AuroraSpacing.space6,
        vertical: AuroraSpacing.space5,
      ),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.lg,
        border: Border.all(
          color: accent ? AuroraTasksCColors.readyRule : AuroraColors.inkBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: a.of(AuroraTasksCSizes.actionGlyph),
            color: accent ? AuroraColors.cobalt : AuroraColors.inkSubtle,
          ),
          SizedBox(width: a.of(AuroraSpacing.space5)),
          Expanded(child: Text(text, style: AuroraTasksCType.infoCard)),
        ],
      ),
    );
  }
}
