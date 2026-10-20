import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_tasks_a.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../tasks_copy.dart';

/// "See all upcoming": the coral text link under NEXT UP.
class TasksSeeUpcomingLink extends StatelessWidget {
  const TasksSeeUpcomingLink({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: TasksCopy.seeAllUpcoming,
      child: Container(
        alignment: Alignment.center,
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraSizes.minTouch),
        ),
        child: Text(
          TasksCopy.seeAllUpcoming,
          style: AuroraTasksAType.coralLink,
        ),
      ),
    );
  }
}
