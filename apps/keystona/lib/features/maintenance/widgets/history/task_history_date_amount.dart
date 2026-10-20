import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';

/// The date at the left and the cost at the right edge. At large text sizes
/// the cost drops below the date instead of squeezing it.
class TaskHistoryDateAmount extends StatelessWidget {
  const TaskHistoryDateAmount({
    super.key,
    required this.date,
    required this.amount,
  });

  final String date;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final dateText = Text(date, style: AuroraTasksBType.historyDate);
    final amountText = Text(amount, style: AuroraTasksBType.amount);
    if (a.textScale >= AuroraTasksB.stackTextScale) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [dateText, amountText],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: dateText),
        SizedBox(width: a.of(AuroraSpacing.space3)),
        amountText,
      ],
    );
  }
}
