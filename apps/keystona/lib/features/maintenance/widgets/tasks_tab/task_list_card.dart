import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_sizes.dart';

/// A bordered card holding task rows with a hairline between them. The
/// overdue list uses the coral outline.
class TaskListCard extends StatelessWidget {
  const TaskListCard({super.key, required this.children, this.overdue = false});

  final List<Widget> children;

  /// Outlines the card in coral (the one coral surface on the screen).
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.xl,
        border: Border.all(
          color: overdue ? AuroraColors.coral : AuroraColors.inkBorder,
          width: overdue ? AuroraBorders.emphasis : AuroraBorders.regular,
        ),
      ),
      child: ClipRRect(
        borderRadius: AuroraRadius.xl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: AuroraBorders.hairline,
                  thickness: AuroraBorders.hairline,
                  color: AuroraColors.inkBorder,
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}
