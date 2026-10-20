import 'package:flutter/cupertino.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_c.dart';
import '../dashed_outline.dart';

/// "What saving does, in one sentence": cobalt outline once the form is
/// ready, a dashed one (and what is missing) before.
class TaskSummaryBox extends StatelessWidget {
  const TaskSummaryBox({super.key, required this.ready, required this.text});

  final bool ready;
  final String text;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final content = Padding(
      padding: a.symmetric(
        horizontal: AuroraSpacing.space6,
        vertical: AuroraSpacing.space5,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            CupertinoIcons.calendar,
            size: a.of(AuroraTasksCSizes.summaryIcon),
            color: ready ? AuroraColors.cobalt : AuroraColors.inkHelper,
          ),
          SizedBox(width: a.of(AuroraSpacing.space4)),
          Expanded(
            child: Text(
              text,
              style: AuroraTasksCType.summary.copyWith(
                color: ready ? AuroraColors.ink : AuroraColors.inkSubtle,
              ),
            ),
          ),
        ],
      ),
    );
    return Semantics(
      liveRegion: true,
      child: ready
          ? DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AuroraRadius.lg,
                border: Border.all(
                  color: AuroraColors.cobalt,
                  width: AuroraBorders.emphasis,
                ),
              ),
              child: content,
            )
          : DashedOutline(radius: AuroraRadius.lg, child: content),
    );
  }
}
