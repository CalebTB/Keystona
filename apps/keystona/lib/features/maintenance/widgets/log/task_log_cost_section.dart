import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_text_field.dart';
import '../shared/task_section_label.dart';
import 'task_log_pair.dart';

/// "Cost": labor and parts, the total at the right of the header, and a line
/// on what it counts toward.
class TaskLogCostSection extends StatelessWidget {
  const TaskLogCostSection({
    super.key,
    required this.labor,
    required this.parts,
    required this.totalText,
    required this.helper,
  });

  final TextEditingController labor;
  final TextEditingController parts;
  final String totalText;
  final String helper;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TaskSectionLabel(
          title: 'Cost',
          trailing: Text(
            totalText,
            textAlign: TextAlign.right,
            style: AuroraTasksBType.costTotal,
          ),
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        TaskLogPair(
          first: AuroraTextField(
            label: 'Labor',
            controller: labor,
            hintText: r'$0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            maxLength: AuroraTasksB.moneyMax,
          ),
          second: AuroraTextField(
            label: 'Parts',
            controller: parts,
            hintText: r'$0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            maxLength: AuroraTasksB.moneyMax,
          ),
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        Text(helper.toUpperCase(), style: AuroraType.helper),
      ],
    );
  }
}
