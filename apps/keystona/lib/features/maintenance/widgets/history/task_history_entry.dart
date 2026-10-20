import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../models/task_finding.dart';
import '../../models/task_history.dart';
import '../../services/task_format.dart';
import '../../services/task_timing.dart';
import '../shared/task_timeline_dot.dart';
import 'task_history_date_amount.dart';
import '../shared/task_timeline_item.dart';

/// One completion on the History timeline: date and cost, how on time it was
/// and who did it, the note, and its photos.
class TaskHistoryEntryView extends StatelessWidget {
  const TaskHistoryEntryView({
    super.key,
    required this.entry,
    required this.isLast,
  });

  final TaskHistoryEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final c = entry.completion;
    final cost = TaskFormat.totalCost(c);
    final notes = c.notes?.trim();
    final words = _timingWords(entry.timing);
    final found = [
      for (final v in c.findings) ?TaskFinding.fromValue(v)?.label,
    ];
    return TaskTimelineItem(
      dotSize: AuroraTasksB.dotHistory,
      dotTop: AuroraTasksB.dotTopHistory,
      isLast: isLast,
      dot: _dot(entry.timing.kind),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TaskHistoryDateAmount(
            date: TaskFormat.dateShort(c.completedDate),
            amount: cost == null ? '—' : TaskFormat.money(cost),
          ),
          SizedBox(height: a.of(AuroraSpacing.space1)),
          Text.rich(
            TextSpan(
              children: [
                if (words != null)
                  TextSpan(
                    text: words.toUpperCase(),
                    style: AuroraTasksBType.timing.copyWith(
                      color: _timingColor(entry.timing.kind),
                    ),
                  ),
                TextSpan(
                  text: words == null
                      ? TaskFormat.doneByLine(c)
                      : ' · ${TaskFormat.doneByLine(c)}',
                  style: AuroraTasksBType.entryMeta,
                ),
              ],
            ),
          ),
          if (notes != null && notes.isNotEmpty) ...[
            SizedBox(height: a.of(AuroraSpacing.space1)),
            Text(notes, style: AuroraTasksBType.entryNote),
          ],
          if (found.isNotEmpty) ...[
            SizedBox(height: a.of(AuroraSpacing.space1)),
            Text(found.join(' · '), style: AuroraTasksBType.entryMeta),
          ],
          if (entry.photos.isNotEmpty) ...[
            SizedBox(height: a.of(AuroraSpacing.space3)),
            Wrap(
              spacing: a.of(AuroraSpacing.space3),
              runSpacing: a.of(AuroraSpacing.space3),
              children: [
                for (final p in entry.photos)
                  _Thumb(url: p.url, label: p.kind?.value),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String? _timingWords(TaskTiming t) => switch (t.kind) {
    TaskTimingKind.early => TaskFormat.timingWords(t.days, late: false),
    TaskTimingKind.late => TaskFormat.timingWords(t.days, late: true),
    TaskTimingKind.onTime => 'On time',
    TaskTimingKind.unknown => null,
  };

  static Color _timingColor(TaskTimingKind k) => switch (k) {
    TaskTimingKind.late => AuroraColors.amberDeep,
    TaskTimingKind.unknown => AuroraColors.inkSecondary,
    _ => AuroraColors.olive,
  };

  static Widget _dot(TaskTimingKind k) => switch (k) {
    TaskTimingKind.early || TaskTimingKind.onTime => const TaskTimelineDot(
      fill: AuroraColors.lime,
      ring: AuroraColors.olive,
    ),
    TaskTimingKind.late => const TaskTimelineDot(
      ring: AuroraColors.amber,
      ringWidth: AuroraTasksB.lateRing,
    ),
    TaskTimingKind.unknown => const TaskTimelineDot(
      ring: AuroraColors.inkBorderStrong,
    ),
  };
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, this.label});

  final String? url;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final side = a.of(AuroraTasksB.entryThumb);
    const placeholder = ColoredBox(
      color: AuroraColors.inkBorder,
      child: Icon(Icons.image_outlined, color: AuroraColors.inkSecondary),
    );
    return Semantics(
      image: true,
      label: label == null ? 'Photo' : '$label photo',
      child: ClipRRect(
        borderRadius: AuroraRadius.tile,
        child: SizedBox.square(
          dimension: side,
          child: url == null
              ? placeholder
              : CachedNetworkImage(
                  imageUrl: url!,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => placeholder,
                  errorWidget: (_, _, _) => placeholder,
                ),
        ),
      ),
    );
  }
}
