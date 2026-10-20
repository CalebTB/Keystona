import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_shared.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../lifespan/lifespan_reading.dart';
import 'lifespan_bar.dart';
import 'lifespan_colors.dart';

/// A system or appliance row: icon tile, name, "model · location", age with
/// "of ~N", the lifespan bar, and below it the status (or a warranty note, or
/// "REPLACE ~YEAR") on the left and "N TASKS" on the right.
///
/// [compact] is the HomeProfile row: bare icon, name, age, a short bar and a
/// chevron. Put rows inside an `ItemRowGroup`.
class ItemListRow extends StatelessWidget {
  const ItemListRow({
    super.key,
    required this.icon,
    required this.name,
    required this.reading,
    this.subtitle,
    this.warrantyNote,
    this.taskCount,
    this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String name;

  /// "Northline NF95-080B · Basement utility room".
  final String? subtitle;
  final LifespanReading reading;

  /// "WARRANTY ENDS DEC 9", shown when there is no status to show.
  final String? warrantyNote;

  /// Open tasks. Null hides the count; 0 shows "0 TASKS".
  final int? taskCount;
  final VoidCallback? onTap;
  final bool compact;

  /// The line under the bar: status, else the warranty note, else
  /// "REPLACE ~YEAR".
  String? get _footnote {
    final status = reading.statusLabel;
    if (status != null) return status;
    if (warrantyNote != null) return warrantyNote!.toUpperCase();
    final year = reading.replaceYear;
    return year == null ? null : 'REPLACE ~$year';
  }

  Color get _footnoteColor {
    if (reading.statusLabel != null) return reading.textColor;
    if (warrantyNote != null) return AuroraColors.amberDeep;
    return AuroraColors.inkSecondary;
  }

  String get _semanticLabel {
    final parts = [
      name,
      if (reading.ageLabel.isNotEmpty) reading.ageLabel,
      if (reading.lifeLabel.isNotEmpty) 'of ${reading.lifeLabel}',
      ?reading.statusLabel,
    ];
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: _semanticLabel,
      child: compact ? _compact(context) : _regular(context),
    );
  }

  Widget _compact(BuildContext context) {
    final a = context.aurora;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: a.minControl(AuroraSizes.minTouch)),
      child: Padding(
        padding: a.symmetric(
          horizontal: AuroraSpacing.space6,
          vertical: AuroraSpacing.space3,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: a.of(AuroraHomeSizes.compactGlyph),
              color: AuroraColors.ink,
            ),
            SizedBox(width: a.of(AuroraSpacing.space5)),
            Expanded(
              child: Text(
                name,
                style: AuroraType.rowTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space3)),
            if (reading.ageLabel.isNotEmpty)
              Text(
                reading.ageLabel.toUpperCase(),
                style: AuroraType.rowDate.copyWith(color: reading.textColor),
              ),
            SizedBox(width: a.of(AuroraSpacing.space3)),
            SizedBox(
              width: a.of(AuroraHomeSizes.compactBarWidth),
              child: LifespanBar(reading: reading),
            ),
            SizedBox(width: a.of(AuroraSpacing.space1)),
            Icon(
              Icons.chevron_right,
              size: a.of(AuroraIconSizes.md),
              color: AuroraColors.inkTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _regular(BuildContext context) {
    final a = context.aurora;
    final footnote = _footnote;
    final tasks = taskCount;
    return Padding(
      padding: a.symmetric(
        horizontal: AuroraSpacing.space6,
        vertical: AuroraSpacing.space5,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: a.of(AuroraHomeSizes.itemTile),
            height: a.of(AuroraHomeSizes.itemTile),
            decoration: BoxDecoration(
              borderRadius: AuroraRadius.tile,
              border: Border.all(
                color: AuroraColors.inkTileBorder,
                width: AuroraBorders.regular,
              ),
            ),
            child: Icon(
              icon,
              size: a.of(AuroraHomeSizes.itemTileGlyph),
              color: AuroraColors.ink,
            ),
          ),
          SizedBox(width: a.of(AuroraSpacing.space5)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AuroraType.h3,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null) ...[
                            SizedBox(height: a.of(AuroraSpacing.space1)),
                            Text(
                              subtitle!,
                              style: AuroraType.meta,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (reading.ageLabel.isNotEmpty) ...[
                      SizedBox(width: a.of(AuroraSpacing.space3)),
                      Flexible(child: _Age(reading: reading)),
                    ],
                  ],
                ),
                SizedBox(height: a.of(AuroraSpacing.space3)),
                LifespanBar(reading: reading),
                if (footnote != null || tasks != null) ...[
                  SizedBox(height: a.of(AuroraSpacing.space2)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          footnote ?? '',
                          style: AuroraHomeType.status.copyWith(
                            color: _footnoteColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (tasks != null) ...[
                        SizedBox(width: a.of(AuroraSpacing.space3)),
                        Flexible(
                          child: Text(
                            '$tasks ${tasks == 1 ? 'TASK' : 'TASKS'}',
                            textAlign: TextAlign.end,
                            style: AuroraType.meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Age extends StatelessWidget {
  const _Age({required this.reading});

  final LifespanReading reading;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: reading.ageLabel,
            style: AuroraHomeType.itemAge.copyWith(color: reading.textColor),
          ),
          if (reading.lifeLabel.isNotEmpty)
            TextSpan(
              text: ' of ${reading.lifeLabel}',
              style: AuroraHomeType.itemOf,
            ),
        ],
      ),
      textAlign: TextAlign.end,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
