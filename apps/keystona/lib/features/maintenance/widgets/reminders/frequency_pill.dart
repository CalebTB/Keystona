import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_c.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../reminders_copy.dart';

/// The small outlined "Every 3 months" pill with a chevron that opens the
/// how-often choices.
class FrequencyPill extends StatelessWidget {
  const FrequencyPill({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: '${RemindersCopy.howOften}, $label',
      enforceTouchTarget: true,
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.of(AuroraTasksCSizes.frequencyPillHeight),
        ),
        padding: a.symmetric(horizontal: AuroraSpacing.space3),
        decoration: BoxDecoration(
          borderRadius: AuroraRadius.sm,
          border: Border.all(
            color: AuroraColors.inkInputBorder,
            width: AuroraBorders.regular,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AuroraTasksCType.frequency,
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space1)),
            Icon(
              Icons.keyboard_arrow_down,
              size: a.of(AuroraTasksCSizes.frequencyChevron),
              color: AuroraColors.inkSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
