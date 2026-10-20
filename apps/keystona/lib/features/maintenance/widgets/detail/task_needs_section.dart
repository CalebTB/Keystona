import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../shared/task_fact_card.dart';
import '../shared/task_section_label.dart';

/// "You'll need": the supplies and tools for the job.
class TaskNeedsSection extends StatelessWidget {
  const TaskNeedsSection({
    super.key,
    required this.supplies,
    required this.tools,
  });

  final List<String> supplies;
  final List<String> tools;

  /// True when there is anything to list.
  static bool hasContent(List<String> supplies, List<String> tools) =>
      supplies.isNotEmpty || tools.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TaskSectionLabel(title: "You'll need"),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        TaskFactCard(
          facts: [
            if (supplies.isNotEmpty) TaskFact('Supplies', supplies.join(', ')),
            if (tools.isNotEmpty) TaskFact('Tools', tools.join(', ')),
          ],
        ),
      ],
    );
  }
}
