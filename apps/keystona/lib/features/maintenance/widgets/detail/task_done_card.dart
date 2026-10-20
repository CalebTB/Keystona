import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// What a finished (or skipped) task shows in place of the due card.
enum TaskResultKind { done, skipped }

/// "Done today, 3 days early" with the next due date and an inline Undo.
/// Done is olive with a lime check; skipped is a quiet ink outline.
class TaskDoneCard extends StatelessWidget {
  const TaskDoneCard({
    super.key,
    required this.kind,
    required this.title,
    this.subtitle,
    this.onUndo,
  });

  final TaskResultKind kind;
  final String title;
  final String? subtitle;

  /// Null hides Undo.
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final done = kind == TaskResultKind.done;
    return Container(
      padding: a.symmetric(
        horizontal: AuroraSpacing.space7,
        vertical: AuroraTasksB.doneCardPadV,
      ),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.banner,
        border: Border.all(
          color: done ? AuroraColors.olive : AuroraColors.inkBorderStrong,
          width: AuroraBorders.emphasis,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: a.of(AuroraTasksB.doneBadge),
            height: a.of(AuroraTasksB.doneBadge),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AuroraColors.lime : AuroraColors.paper,
              border: done
                  ? null
                  : Border.all(
                      color: AuroraColors.inkBorderStrong,
                      width: AuroraBorders.regular,
                    ),
            ),
            child: ExcludeSemantics(
              child: Icon(
                done ? Icons.check : Icons.redo,
                size: a.of(AuroraTasksB.doneGlyph),
                color: done ? AuroraColors.olive : AuroraColors.inkSecondary,
              ),
            ),
          ),
          SizedBox(width: a.of(AuroraSpacing.space5)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AuroraTasksBType.doneTitle),
                if (subtitle != null) ...[
                  SizedBox(height: a.of(AuroraTasksB.hairlineGap)),
                  Text(
                    subtitle!.toUpperCase(),
                    style: AuroraType.meta.copyWith(
                      color: AuroraColors.inkSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onUndo != null) ...[
            SizedBox(width: a.of(AuroraSpacing.space3)),
            AuroraPressable(
              onTap: onUndo,
              semanticLabel: 'Undo',
              enforceTouchTarget: true,
              child: Text(
                'Undo',
                style: AuroraType.buttonSm.copyWith(
                  color: AuroraColors.coralDeep,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
