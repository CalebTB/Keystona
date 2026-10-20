import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/aurora/aurora_chip.dart';
import '../../models/task_log_draft.dart';
import '../shared/task_section_label.dart';
import 'task_log_pro_card.dart';

/// "Who did it": Me or A pro, and for a pro the card to pick who.
class TaskLogWhoSection extends StatelessWidget {
  const TaskLogWhoSection({
    super.key,
    required this.doer,
    required this.pro,
    required this.onDoer,
    required this.onPickPro,
    required this.onClearPro,
  });

  final TaskDoer doer;
  final TaskPro? pro;
  final ValueChanged<TaskDoer> onDoer;
  final VoidCallback onPickPro;
  final VoidCallback onClearPro;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TaskSectionLabel(title: 'Who did it'),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        Wrap(
          spacing: a.of(AuroraSpacing.space2),
          runSpacing: a.of(AuroraSpacing.space2),
          children: [
            FilterPill(
              label: 'Me',
              selected: doer == TaskDoer.me,
              onTap: () => onDoer(TaskDoer.me),
            ),
            FilterPill(
              label: 'A pro',
              selected: doer == TaskDoer.pro,
              onTap: () => onDoer(TaskDoer.pro),
            ),
          ],
        ),
        if (doer == TaskDoer.pro) ...[
          SizedBox(height: a.of(AuroraSpacing.space5)),
          TaskLogProCard(pro: pro, onTap: onPickPro, onClear: onClearPro),
        ],
      ],
    );
  }
}
