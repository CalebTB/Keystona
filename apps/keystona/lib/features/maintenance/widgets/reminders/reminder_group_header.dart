import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_c.dart';
import '../../../../core/theme/aurora_typography.dart';

/// Group title on the left, a count, reason or link on the right.
class ReminderGroupHeader extends StatelessWidget {
  const ReminderGroupHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    // Flexible + spaceBetween, not Expanded + Flexible: that pair splits the
    // row evenly and leaves the trailing widget floating mid-row.
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: a.of(AuroraTasksCSizes.sectionHeaderMinHeight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Semantics(
              header: true,
              child: Text(title.toUpperCase(), style: AuroraType.label),
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: a.of(AuroraSpacing.space3)),
            Flexible(child: trailing!),
          ],
        ],
      ),
    );
  }
}

/// The small uppercase note used as a header's trailing text.
class ReminderHeaderNote extends StatelessWidget {
  const ReminderHeaderNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    textAlign: TextAlign.end,
    style: AuroraType.meta,
  );
}
