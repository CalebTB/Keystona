import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../shared/task_fact_card.dart';
import '../shared/task_section_label.dart';

/// "Schedule": how often it repeats, what comes next, when the reminder goes
/// out and where the task came from.
class TaskScheduleSection extends StatelessWidget {
  const TaskScheduleSection({super.key, required this.facts});

  final List<TaskFact> facts;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TaskSectionLabel(title: 'Schedule'),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        TaskFactCard(facts: facts),
      ],
    );
  }
}
