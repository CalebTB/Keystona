import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../services/task_instructions.dart';
import '../shared/task_section_label.dart';

/// "How to do it": the instructions as numbered steps.
class TaskStepsSection extends StatelessWidget {
  const TaskStepsSection({super.key, required this.steps});

  /// Step text, `**bold**` allowed.
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TaskSectionLabel(title: 'How to do it'),
        SizedBox(height: a.of(AuroraSpacing.space5)),
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) SizedBox(height: a.of(AuroraTasksB.stepGap)),
          _Step(number: i + 1, text: steps[i]),
        ],
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final base = AuroraTasksBType.step;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: a.of(AuroraTasksB.stepCircle),
          height: a.of(AuroraTasksB.stepCircle),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AuroraColors.ink,
              width: AuroraBorders.emphasis,
            ),
          ),
          child: Text('$number', style: AuroraTasksBType.stepNumber),
        ),
        SizedBox(width: a.of(AuroraSpacing.space5)),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: a.of(AuroraTasksB.hairlineGap)),
            child: Text.rich(
              TextSpan(
                children: [
                  for (final s in TaskInstructions.spans(text))
                    TextSpan(
                      text: s.text,
                      style: s.bold
                          ? base.copyWith(fontWeight: FontWeight.w700)
                          : base,
                    ),
                ],
              ),
              style: base,
            ),
          ),
        ),
      ],
    );
  }
}
