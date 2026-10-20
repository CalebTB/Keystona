import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_button.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// The open task's due card: when it is due, Mark done / Not now, and a link
/// to log cost, photos or a receipt. The ring color says how urgent it is.
class TaskDueCard extends StatelessWidget {
  const TaskDueCard({
    super.key,
    required this.ring,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onMarkDone,
    required this.onNotNow,
    required this.onAddDetails,
    this.busy = false,
  });

  /// Card and calendar-tile outline.
  final Color ring;

  /// Second-line color.
  final Color accent;
  final String title;

  /// "IN 3 DAYS · REMINDER WENT OUT SEP 30" (uppercased here).
  final String subtitle;
  final VoidCallback onMarkDone;
  final VoidCallback onNotNow;
  final VoidCallback onAddDetails;

  /// True while a write is running: Mark done shows its spinner.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final stacked = a.textScale >= AuroraTasksB.stackTextScale;
    final markDone = PrimaryButton(
      label: 'Mark done',
      expand: true,
      loading: busy,
      onPressed: busy ? null : onMarkDone,
    );
    final notNow = SecondaryButton(
      label: 'Not now',
      expand: stacked,
      onPressed: busy ? null : onNotNow,
    );
    return Container(
      padding: a.all(AuroraSpacing.space7),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.banner,
        border: Border.all(color: ring, width: AuroraBorders.emphasis),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _CalendarTile(ring: ring, glyph: accent),
              SizedBox(width: a.of(AuroraSpacing.space5)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AuroraTasksBType.dueTitle),
                    SizedBox(height: a.of(AuroraTasksB.hairlineGap)),
                    Text(
                      subtitle.toUpperCase(),
                      style: AuroraType.meta.copyWith(
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: a.of(AuroraSpacing.space6)),
          if (stacked) ...[
            markDone,
            SizedBox(height: a.of(AuroraSpacing.space3)),
            notNow,
          ] else
            Row(
              children: [
                Expanded(child: markDone),
                SizedBox(width: a.of(AuroraSpacing.space3)),
                notNow,
              ],
            ),
          SizedBox(height: a.of(AuroraSpacing.space5)),
          const Divider(
            height: AuroraBorders.hairline,
            thickness: AuroraBorders.hairline,
            color: AuroraColors.inkBorder,
          ),
          AuroraPressable(
            onTap: onAddDetails,
            semanticLabel: 'Done, add cost, photos or a receipt',
            enforceTouchTarget: true,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Done — add cost, photos or a receipt',
                    style: AuroraTasksBType.linkRow,
                  ),
                ),
                SizedBox(width: a.of(AuroraSpacing.space3)),
                Icon(
                  Icons.chevron_right,
                  size: a.of(AuroraIconSizes.sm),
                  color: AuroraColors.inkPlaceholder,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarTile extends StatelessWidget {
  const _CalendarTile({required this.ring, required this.glyph});

  final Color ring;
  final Color glyph;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      width: a.of(AuroraTasksB.dueTile),
      height: a.of(AuroraTasksB.dueTile),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.md,
        border: Border.all(color: ring, width: AuroraBorders.emphasis),
      ),
      child: ExcludeSemantics(
        child: Icon(
          Icons.calendar_today_outlined,
          size: a.of(AuroraTasksB.dueGlyph),
          color: glyph,
        ),
      ),
    );
  }
}
