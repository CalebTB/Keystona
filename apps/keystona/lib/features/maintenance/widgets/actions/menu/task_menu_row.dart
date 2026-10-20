import 'package:flutter/material.dart';

import '../../../../../core/theme/aurora_colors.dart';
import '../../../../../core/theme/aurora_scale.dart';
import '../../../../../core/theme/aurora_spacing.dart';
import '../../../../../core/theme/aurora_tasks_a.dart';
import '../../../../../core/widgets/aurora/aurora_pressable.dart';

/// One row of the long-press menu: a glyph, a title with an optional second
/// line, and an optional trailing widget (chevron).
class TaskMenuRow extends StatelessWidget {
  const TaskMenuRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.destructive = false,
    this.expanded,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  /// Draws the title in coral and the glyph to match.
  final bool destructive;

  /// For a row that opens inline options: whether they are showing.
  final bool? expanded;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final color = destructive ? AuroraColors.coralDeep : AuroraColors.ink;
    return Semantics(
      expanded: expanded,
      child: AuroraPressable(
        onTap: onTap,
        semanticLabel: subtitle == null ? title : '$title. $subtitle',
        child: Container(
          constraints: BoxConstraints(
            minHeight: a.minControl(
              subtitle == null
                  ? AuroraTasksA.menuRowShortMinHeight
                  : AuroraTasksA.menuRowMinHeight,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: a.of(AuroraSpacing.space7),
            vertical: a.of(AuroraSpacing.space5),
          ),
          child: Row(
            children: [
              Icon(icon, size: a.of(AuroraTasksA.menuGlyph), color: color),
              SizedBox(width: a.of(AuroraSpacing.space6)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AuroraTasksAType.menuTitle.copyWith(color: color),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: a.of(AuroraSpacing.space1)),
                      Text(subtitle!, style: AuroraTasksAType.menuSub),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: a.of(AuroraSpacing.space3)),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
