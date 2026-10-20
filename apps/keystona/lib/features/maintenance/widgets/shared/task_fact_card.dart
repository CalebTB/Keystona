import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../../../core/theme/aurora_typography.dart';

/// One label/value line in a [TaskFactCard].
class TaskFact {
  const TaskFact(this.label, this.value);

  final String label;
  final String value;
}

/// Bordered card of label/value rows separated by hairlines ("You'll need",
/// "Schedule"). Long values wrap; nothing is clipped.
class TaskFactCard extends StatelessWidget {
  const TaskFactCard({super.key, required this.facts});

  final List<TaskFact> facts;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    // Large text: label above value, so neither is squeezed.
    final stacked = a.textScale >= AuroraTasksB.stackTextScale;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.xl,
        border: Border.all(
          color: AuroraColors.inkBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: ClipRRect(
        borderRadius: AuroraRadius.xl,
        child: Column(
          children: [
            for (var i = 0; i < facts.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: AuroraBorders.hairline,
                  thickness: AuroraBorders.hairline,
                  color: AuroraColors.inkBorder,
                ),
              Padding(
                padding: a.symmetric(
                  horizontal: AuroraSpacing.space6,
                  vertical: AuroraSpacing.space5,
                ),
                child: stacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            facts[i].label.toUpperCase(),
                            style: AuroraType.label,
                          ),
                          SizedBox(height: a.of(AuroraSpacing.space2)),
                          Text(facts[i].value, style: AuroraType.buttonSm),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // The label takes its natural width; the value takes
                          // the rest and sits at the right edge.
                          Text(
                            facts[i].label.toUpperCase(),
                            style: AuroraType.label,
                          ),
                          SizedBox(width: a.of(AuroraSpacing.space5)),
                          Expanded(
                            child: Text(
                              facts[i].value,
                              textAlign: TextAlign.right,
                              style: AuroraType.buttonSm,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
