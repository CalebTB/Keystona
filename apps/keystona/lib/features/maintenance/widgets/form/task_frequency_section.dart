import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_motion.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../models/task_form_options.dart';
import '../../task_form_copy.dart';
import 'task_option_field.dart';
import 'task_years_slider.dart';

/// "How often" and, for "Every few years", the years slider.
class TaskFrequencySection extends StatelessWidget {
  const TaskFrequencySection({
    super.key,
    required this.frequency,
    required this.years,
    required this.onFrequency,
    required this.onYears,
  });

  final TaskFrequency frequency;
  final int years;
  final ValueChanged<TaskFrequency> onFrequency;
  final ValueChanged<int> onYears;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TaskOptionField<TaskFrequency>(
          label: TaskFormCopy.frequencyLabel,
          sheetTitle: TaskFormCopy.chooseFrequency,
          required: true,
          choices: TaskFrequency.values,
          value: frequency,
          labelOf: (f) => f.label,
          onChanged: onFrequency,
        ),
        AnimatedSize(
          duration: AuroraDurations.fast,
          alignment: Alignment.topCenter,
          child: frequency == TaskFrequency.everyFewYears
              ? Padding(
                  padding: EdgeInsets.only(top: a.of(AuroraSpacing.space5)),
                  child: TaskYearsSlider(years: years, onChanged: onYears),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
