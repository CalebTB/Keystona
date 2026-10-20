import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_c.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../models/task_form_options.dart';
import '../../task_form_copy.dart';

/// "Every few years": the "EVERY" label, "3 years", and a slider, set apart
/// by a cobalt rule on the left.
class TaskYearsSlider extends StatelessWidget {
  const TaskYearsSlider({
    super.key,
    required this.years,
    required this.onChanged,
  });

  final int years;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      padding: EdgeInsets.only(left: a.of(AuroraSpacing.space6)),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AuroraTasksCColors.yearsRule,
            width: AuroraTasksCSizes.yearsRule,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  TaskFormCopy.everyLabel.toUpperCase(),
                  style: AuroraType.label,
                ),
              ),
              SizedBox(width: a.of(AuroraSpacing.space3)),
              Flexible(
                child: Text(
                  TaskFormCopy.years(years),
                  textAlign: TextAlign.end,
                  style: AuroraTasksCType.yearsValue,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AuroraColors.cobalt,
              inactiveTrackColor: AuroraColors.inkTrackOff,
              thumbColor: AuroraColors.cobalt,
              overlayColor: AuroraColors.focusCobalt,
              activeTickMarkColor: AuroraStructure.transparent,
              inactiveTickMarkColor: AuroraStructure.transparent,
            ),
            child: Slider(
              min: YearsRange.min.toDouble(),
              max: YearsRange.max.toDouble(),
              divisions: YearsRange.max - YearsRange.min,
              value: years.toDouble(),
              label: TaskFormCopy.years(years),
              semanticFormatterCallback: (v) => TaskFormCopy.years(v.round()),
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }
}
