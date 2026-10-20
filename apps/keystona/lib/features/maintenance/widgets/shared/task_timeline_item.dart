import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_tasks_b.dart';

/// One entry on a timeline: a dot, the connector line down to the next entry,
/// and the [child] content. The line runs behind the content, so it grows
/// with it at any text size.
class TaskTimelineItem extends StatelessWidget {
  const TaskTimelineItem({
    super.key,
    required this.dot,
    required this.dotSize,
    required this.dotTop,
    required this.isLast,
    required this.child,
  });

  /// The dot, drawn at [dotSize] square.
  final Widget dot;
  final double dotSize;

  /// Space above the dot so it lines up with the first text line.
  final double dotTop;
  final bool isLast;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final size = a.of(dotSize);
    final top = a.of(dotTop);
    return Stack(
      children: [
        if (!isLast)
          Positioned(
            left: (size - AuroraTasksB.timelineLine) / 2,
            top: top + size,
            bottom: 0,
            width: AuroraTasksB.timelineLine,
            child: const ColoredBox(color: AuroraColors.inkBorderStrong),
          ),
        Padding(
          padding: EdgeInsets.only(
            bottom: isLast ? 0 : a.of(AuroraTasksB.timelineEntryGap),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: top),
                child: SizedBox.square(dimension: size, child: dot),
              ),
              SizedBox(width: a.of(AuroraTasksB.timelineGap)),
              Expanded(child: child),
            ],
          ),
        ),
      ],
    );
  }
}
