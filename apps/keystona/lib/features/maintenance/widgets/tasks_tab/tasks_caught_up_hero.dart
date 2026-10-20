import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_a.dart';
import '../../tasks_copy.dart';

/// The celebration of TasksCaughtUp: a lime circle, "You're all caught up" and
/// a line about the score. The one place a lime fill is a big shape.
class TasksCaughtUpHero extends StatelessWidget {
  const TasksCaughtUpHero({super.key});

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        a.of(AuroraSpacing.space5),
        a.of(AuroraSpacing.space9),
        a.of(AuroraSpacing.space5),
        a.of(AuroraSpacing.space3),
      ),
      child: Column(
        children: [
          Container(
            width: a.of(AuroraTasksA.celebrate),
            height: a.of(AuroraTasksA.celebrate),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AuroraColors.lime,
            ),
            child: Icon(
              Icons.check,
              size: a.of(AuroraTasksA.celebrateGlyph),
              color: AuroraColors.olive,
            ),
          ),
          SizedBox(height: a.of(AuroraSpacing.space5)),
          Text(
            TasksCopy.caughtUpTitle,
            textAlign: TextAlign.center,
            style: AuroraTasksAType.celebrateTitle,
          ),
          SizedBox(height: a.of(AuroraSpacing.space5)),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: a.of(AuroraTasksA.celebrateBodyMaxWidth),
            ),
            child: Text(
              TasksCopy.caughtUpBody,
              textAlign: TextAlign.center,
              style: AuroraTasksAType.celebrateBody,
            ),
          ),
        ],
      ),
    );
  }
}
