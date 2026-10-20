import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_sizes.dart';

/// The bordered card holding a group's rows, with a hairline between them.
class ReminderGroupCard extends StatelessWidget {
  const ReminderGroupCard({super.key, required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: AuroraRadius.xl,
        border: Border.all(
          color: AuroraColors.inkBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(
                height: AuroraBorders.hairline,
                thickness: AuroraBorders.hairline,
                color: AuroraColors.inkBorder,
              ),
            rows[i],
          ],
        ],
      ),
    );
  }
}
