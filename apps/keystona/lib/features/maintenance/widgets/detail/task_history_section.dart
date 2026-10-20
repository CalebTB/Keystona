import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../services/task_timing.dart';
import '../shared/task_section_label.dart';
import '../shared/task_timeline_dot.dart';
import '../shared/task_timeline_item.dart';

/// One completion in the detail's history card.
class TaskHistoryRow {
  const TaskHistoryRow({
    required this.eyebrow,
    required this.timing,
    required this.who,
    this.amount,
    this.justDone = false,
  });

  /// "JUL 6, 2026 · ON TIME" (uppercased here).
  final String eyebrow;
  final TaskTimingKind timing;

  /// "You · 10 min", "Summit Heating & Air".
  final String who;

  /// "$24"; null draws a dash.
  final String? amount;

  /// Done today: the dot is olive.
  final bool justDone;
}

/// "History · 3" with "On time 2 of 3", the latest entries on a timeline, and
/// a tap target that opens the full history.
class TaskHistorySection extends StatelessWidget {
  const TaskHistorySection({
    super.key,
    required this.count,
    required this.rows,
    required this.onOpen,
    this.onTimeText,
  });

  final int count;
  final List<TaskHistoryRow> rows;
  final VoidCallback onOpen;

  /// "ON TIME 2 OF 3"; null when no completion has a known due date.
  final String? onTimeText;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TaskSectionLabel(
          title: 'History · $count',
          trailing: onTimeText == null
              ? null
              : Text(
                  onTimeText!.toUpperCase(),
                  textAlign: TextAlign.right,
                  style: AuroraType.rowDate,
                ),
        ),
        SizedBox(height: a.of(AuroraSpacing.space4)),
        AuroraPressable(
          onTap: onOpen,
          semanticLabel: 'Open the full history',
          child: Container(
            padding: a.symmetric(
              horizontal: AuroraSpacing.space6,
              vertical: AuroraSpacing.space7,
            ),
            decoration: BoxDecoration(
              borderRadius: AuroraRadius.xl,
              border: Border.all(
                color: AuroraColors.inkBorder,
                width: AuroraBorders.regular,
              ),
            ),
            child: rows.isEmpty
                ? Text('Nothing logged yet.', style: AuroraTasksBType.entryMeta)
                : Column(
                    children: [
                      for (var i = 0; i < rows.length; i++)
                        TaskTimelineItem(
                          dotSize: AuroraTasksB.dotDetail,
                          dotTop: AuroraTasksB.dotTopDetail,
                          isLast: i == rows.length - 1,
                          dot: _dot(rows[i]),
                          child: _Row(row: rows[i]),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  static Widget _dot(TaskHistoryRow r) {
    if (r.justDone) return const TaskTimelineDot(fill: AuroraColors.olive);
    if (r.timing == TaskTimingKind.late) {
      return const TaskTimelineDot(ring: AuroraColors.amber);
    }
    return const TaskTimelineDot(fill: AuroraColors.ink);
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.row});

  final TaskHistoryRow row;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final late = row.timing == TaskTimingKind.late;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          row.eyebrow.toUpperCase(),
          style: AuroraType.label.copyWith(
            color: late ? AuroraColors.amberDeep : AuroraColors.inkSecondary,
          ),
        ),
        SizedBox(height: a.of(AuroraTasksB.hairlineGap)),
        _TitleAndAmount(amount: row.amount ?? '—'),
        SizedBox(height: a.of(AuroraTasksB.hairlineGap)),
        Text(row.who, style: AuroraTasksBType.entryMeta),
      ],
    );
  }
}

/// "Done" at the left and the cost at the right edge; at large text sizes the
/// cost drops below instead of squeezing the title.
class _TitleAndAmount extends StatelessWidget {
  const _TitleAndAmount({required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final title = Text('Done', style: AuroraTasksBType.itemTitle);
    final amountText = Text(amount, style: AuroraTasksBType.amount);
    if (a.textScale >= AuroraTasksB.stackTextScale) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [title, amountText],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: title),
        SizedBox(width: a.of(AuroraSpacing.space3)),
        amountText,
      ],
    );
  }
}
