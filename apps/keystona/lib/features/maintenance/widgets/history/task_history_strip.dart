import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../models/task_history.dart';
import '../shared/task_section_label.dart';
import 'task_hatch_fill.dart';

/// "Every time, oldest to newest": one bar per completion or skip, lime for
/// on time, an amber ring for late, hatched for skipped and a plain ring when
/// the due date is unknown. A legend names what they mean.
class TaskHistoryStrip extends StatelessWidget {
  const TaskHistoryStrip({super.key, required this.marks});

  /// Oldest first. Only the latest [AuroraTasksB.stripMax] are drawn.
  final List<HistoryMark> marks;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final shown = marks.length > AuroraTasksB.stripMax
        ? marks.sublist(marks.length - AuroraTasksB.stripMax)
        : marks;
    int count(HistoryMark m) => marks.where((x) => x == m).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TaskSectionLabel(title: 'Every time, oldest → newest'),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        Semantics(
          label:
              '${count(HistoryMark.onTime)} on time, '
              '${count(HistoryMark.late)} late, '
              '${count(HistoryMark.skipped)} skipped',
          child: ExcludeSemantics(
            child: Row(
              children: [
                for (var i = 0; i < shown.length; i++) ...[
                  if (i > 0) SizedBox(width: a.of(AuroraTasksB.stripGap)),
                  Expanded(child: _Bar(mark: shown[i])),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        Wrap(
          spacing: a.of(AuroraSpacing.space6),
          runSpacing: a.of(AuroraSpacing.space2),
          children: const [
            _LegendItem(
              label: 'On time',
              fill: AuroraColors.lime,
              ring: AuroraColors.olive,
              text: AuroraColors.olive,
            ),
            _LegendItem(
              label: 'Late',
              fill: AuroraColors.paper,
              ring: AuroraColors.amber,
              text: AuroraColors.amberDeep,
              emphasis: true,
            ),
            _LegendItem(
              label: 'Skipped',
              fill: AuroraColors.paper,
              ring: AuroraColors.inkBorderStrong,
              text: AuroraColors.inkSubtle,
              hatched: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.mark});

  final HistoryMark mark;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final good = mark == HistoryMark.onTime;
    final late = mark == HistoryMark.late;
    final skipped = mark == HistoryMark.skipped;
    return Container(
      height: a.of(AuroraTasksB.stripBar),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: good ? AuroraColors.lime : AuroraColors.paper,
        borderRadius: AuroraRadius.xs,
        border: Border.all(
          color: good
              ? AuroraColors.olive
              : late
              ? AuroraColors.amber
              : AuroraColors.inkBorderStrong,
          width: late ? AuroraTasksB.lateRing : AuroraBorders.emphasis,
        ),
      ),
      child: skipped ? const TaskHatchFill() : null,
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.fill,
    required this.ring,
    required this.text,
    this.emphasis = false,
    this.hatched = false,
  });

  final String label;
  final Color fill;
  final Color ring;
  final Color text;
  final bool emphasis;
  final bool hatched;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: a.of(AuroraTasksB.legendSwatch),
          height: a.of(AuroraTasksB.legendSwatch),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: AuroraRadius.xs,
            border: Border.all(
              color: ring,
              width: emphasis ? AuroraTasksB.lateRing : AuroraBorders.emphasis,
            ),
          ),
          child: hatched ? const TaskHatchFill() : null,
        ),
        SizedBox(width: a.of(AuroraTasksB.legendGap)),
        Text(
          label.toUpperCase(),
          style: AuroraTasksBType.legend.copyWith(color: text),
        ),
      ],
    );
  }
}
