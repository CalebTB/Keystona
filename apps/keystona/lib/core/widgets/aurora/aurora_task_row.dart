import 'package:flutter/material.dart';

import '../../theme/aurora_colors.dart';
import '../../theme/aurora_radius.dart';
import '../../theme/aurora_scale.dart';
import '../../theme/aurora_sizes.dart';
import '../../theme/aurora_spacing.dart';
import '../../theme/aurora_typography.dart';
import 'aurora_card.dart';
import 'aurora_pressable.dart';

/// Task list row — Aurora style.
///
/// Paper with an ink 12% border. Urgency is a colored left rule plus words,
/// never a tinted fill:
///   Overdue:   coral rule, the due label in coralDeep
///   Due today: amber rule ("soon")
///   Done:      olive check circle, struck-through title
///
/// Leading is the 44 pt check button when [onToggle] is given, otherwise the
/// outlined icon tile when [iconData] is given. Long-press ([onLongPress])
/// opens the row's context menu — there is no ⋯ button.
class AuroraTaskRow extends StatelessWidget {
  const AuroraTaskRow({
    super.key,
    required this.name,
    required this.dueLabel,
    required this.metaLine,
    required this.onTap,
    this.iconData,
    this.iconBackground,
    this.iconColor,
    this.overdue = false,
    this.dueToday = false,
    this.done = false,
    this.onToggle,
    this.onLongPress,
  });

  final String name;

  /// Formatted date string, e.g. "JUN 30".
  final String dueLabel;

  /// Secondary meta text, e.g. "DUE IN 8 DAYS · 10 MIN".
  final String metaLine;

  final VoidCallback onTap;

  final IconData? iconData;

  /// Optional solid fill behind the icon; the tile is outlined when null.
  final Color? iconBackground;
  final Color? iconColor;

  /// Task is past its due date.
  final bool overdue;

  /// Task is due today.
  final bool dueToday;

  /// Task is completed.
  final bool done;

  /// Tap on the check circle. Shows the circle when non-null.
  final VoidCallback? onToggle;

  final VoidCallback? onLongPress;

  Color? get _accent {
    if (done) return null;
    if (overdue) return AuroraColors.coral;
    if (dueToday) return AuroraColors.amber;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraCard(
      onTap: onTap,
      onLongPress: onLongPress,
      accentColor: _accent,
      padding: a.symmetric(
        horizontal: AuroraSpacing.space5,
        vertical: AuroraSpacing.space3,
      ),
      child: Row(
        children: [
          if (onToggle != null) ...[
            _CheckCircle(done: done, onTap: onToggle!),
            SizedBox(width: a.of(AuroraSpacing.space3)),
          ] else if (iconData != null) ...[
            Container(
              width: a.of(AuroraSizes.iconTile),
              height: a.of(AuroraSizes.iconTile),
              decoration: BoxDecoration(
                color: iconBackground ?? AuroraColors.paper,
                borderRadius: AuroraRadius.sm,
                border: Border.all(
                  color: AuroraColors.inkTileBorder,
                  width: AuroraBorders.regular,
                ),
              ),
              child: Icon(
                iconData,
                size: a.of(AuroraIconSizes.sm),
                color: iconColor ?? AuroraColors.ink,
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space5)),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AuroraType.rowTitle.copyWith(
                    decoration: done ? TextDecoration.lineThrough : null,
                    color: done ? AuroraColors.inkHelper : AuroraColors.ink,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: a.of(AuroraSpacing.space1)),
                Text(
                  metaLine.toUpperCase(),
                  style: AuroraType.meta,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: a.of(AuroraSpacing.space3)),
          Text(
            dueLabel.toUpperCase(),
            textAlign: TextAlign.end,
            style: AuroraType.rowDate.copyWith(
              color: overdue && !done
                  ? AuroraColors.coralDeep
                  : AuroraColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 24 pt circle inside a 44 pt touch target. Done = olive fill, lime check.
class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.done, required this.onTap});

  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Semantics(
      checked: done,
      child: AuroraPressable(
        onTap: onTap,
        enforceTouchTarget: true,
        child: Container(
          width: a.of(AuroraSizes.checkCircle),
          height: a.of(AuroraSizes.checkCircle),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AuroraColors.olive : AuroraColors.paper,
            border: Border.all(
              color: done ? AuroraColors.olive : AuroraColors.inkCheckBorder,
              width: AuroraBorders.emphasis,
            ),
          ),
          child: done
              ? Icon(
                  Icons.check,
                  size: a.of(AuroraIconSizes.xs),
                  color: AuroraColors.lime,
                )
              : null,
        ),
      ),
    );
  }
}
