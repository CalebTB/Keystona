import 'package:flutter/material.dart';

import '../../../../../core/theme/aurora_scale.dart';
import '../../../../../core/theme/aurora_spacing.dart';
import '../../../../../core/theme/aurora_tasks_a.dart';
import '../../../../../core/widgets/aurora/aurora_text_field.dart';
import '../../../tasks_copy.dart';

/// COST and QUICK NOTE side by side; stacked when the text is large.
class QuickDoneFields extends StatelessWidget {
  const QuickDoneFields({super.key, required this.cost, required this.note});

  final TextEditingController cost;
  final TextEditingController note;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final costField = AuroraTextField(
      label: TasksCopy.cost,
      controller: cost,
      hintText: TasksCopy.costHint,
      helperText: TasksCopy.costHelp,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
    final noteField = AuroraTextField(
      label: TasksCopy.quickNote,
      controller: note,
      hintText: TasksCopy.optional,
    );
    final gap = a.of(AuroraSpacing.space3);

    if (a.textScale >= AuroraTasksA.stackTextScale) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          costField,
          SizedBox(height: gap),
          noteField,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: AuroraTasksA.costFlex, child: costField),
        SizedBox(width: gap),
        Expanded(flex: AuroraTasksA.noteFlex, child: noteField),
      ],
    );
  }
}
