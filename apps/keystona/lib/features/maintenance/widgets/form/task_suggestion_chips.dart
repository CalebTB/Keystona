import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_c.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// "Common tasks · tap to fill in": outlined "+ label" pills that wrap.
class TaskSuggestionChips extends StatelessWidget {
  const TaskSuggestionChips({
    super.key,
    required this.title,
    required this.labels,
    required this.onPick,
  });

  final String title;
  final List<String> labels;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: AuroraType.helper),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        Wrap(
          spacing: a.of(AuroraSpacing.space3),
          runSpacing: a.of(AuroraSpacing.space3),
          children: [
            for (final label in labels)
              AuroraPressable(
                onTap: () => onPick(label),
                semanticLabel: label,
                enforceTouchTarget: true,
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: a.of(AuroraSizes.chipHeight),
                  ),
                  padding: a.symmetric(horizontal: AuroraSpacing.space5),
                  decoration: BoxDecoration(
                    borderRadius: AuroraRadius.full,
                    border: Border.all(
                      color: AuroraColors.inkInputBorder,
                      width: AuroraBorders.regular,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        size: a.of(AuroraTasksCSizes.suggestionPlus),
                        color: AuroraColors.cobalt,
                      ),
                      SizedBox(width: a.of(AuroraSpacing.space2)),
                      Flexible(child: Text(label, style: AuroraType.chip)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
