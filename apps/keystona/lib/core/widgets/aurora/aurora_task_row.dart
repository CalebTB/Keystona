import 'package:flutter/material.dart';

import '../../theme/aurora_colors.dart';
import '../../theme/aurora_radius.dart';
import '../../theme/aurora_spacing.dart';
import '../../theme/aurora_typography.dart';

/// Task list row — Aurora style.
///
/// Background varies by urgency:
///   Default:   paper + inkBorder
///   Overdue:   coralDim, no border
///   Due today: lime, no border
///
/// Icon tile is 30×30 with radius-sm (8px) and category-specific color.
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
  });

  final String name;

  /// Formatted date string, e.g. "JUN 30". Rendered in mono.
  final String dueLabel;

  /// Secondary meta text, e.g. "DUE IN 8 DAYS · 10 MIN".
  final String metaLine;

  final VoidCallback onTap;

  final IconData? iconData;
  final Color? iconBackground;
  final Color? iconColor;

  /// Task is past its due date.
  final bool overdue;

  /// Task is due today.
  final bool dueToday;

  Color get _background {
    if (overdue) return AuroraColors.coralDim;
    if (dueToday) return AuroraColors.lime;
    return AuroraColors.paper;
  }

  bool get _hasBorder => !overdue && !dueToday;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AuroraSpacing.space5,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: _background,
          borderRadius: AuroraRadius.lg,
          border: _hasBorder
              ? Border.all(color: AuroraColors.inkBorder)
              : null,
        ),
        child: Row(
          children: [
            // Icon tile
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconBackground ?? AuroraColors.butter,
                borderRadius: AuroraRadius.sm,
              ),
              child: iconData != null
                  ? Icon(iconData, size: 16, color: iconColor ?? AuroraColors.ink)
                  : null,
            ),
            const SizedBox(width: AuroraSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AuroraType.h3.copyWith(fontSize: 12.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    metaLine.toUpperCase(),
                    style: AuroraType.label.copyWith(
                      color: AuroraColors.inkSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AuroraSpacing.space3),
            Text(
              dueLabel.toUpperCase(),
              style: AuroraType.label.copyWith(
                fontWeight: FontWeight.w600,
                color: overdue ? AuroraColors.coralDeep : AuroraColors.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
