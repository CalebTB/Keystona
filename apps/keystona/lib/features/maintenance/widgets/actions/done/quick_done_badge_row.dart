import 'package:flutter/material.dart';

import '../../../../../core/theme/aurora_colors.dart';
import '../../../../../core/theme/aurora_scale.dart';
import '../../../../../core/theme/aurora_sizes.dart';
import '../../../../../core/theme/aurora_spacing.dart';
import '../../../../../core/theme/aurora_tasks_a.dart';

/// The lime done badge with the task name and "DONE · NEXT ONE …".
class QuickDoneBadgeRow extends StatelessWidget {
  const QuickDoneBadgeRow({super.key, required this.name, required this.meta});

  final String name;
  final String meta;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Row(
      children: [
        Container(
          width: a.of(AuroraTasksA.doneSheetBadge),
          height: a.of(AuroraTasksA.doneSheetBadge),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AuroraColors.lime,
            border: Border.all(
              color: AuroraColors.olive,
              width: AuroraBorders.emphasis,
            ),
          ),
          child: Icon(
            Icons.check,
            size: a.of(AuroraTasksA.doneSheetGlyph),
            color: AuroraColors.olive,
          ),
        ),
        SizedBox(width: a.of(AuroraSpacing.space6)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AuroraTasksAType.sheetHeading),
              SizedBox(height: a.of(AuroraSpacing.space1)),
              Text(meta, style: AuroraTasksAType.doneMeta),
            ],
          ),
        ),
      ],
    );
  }
}
