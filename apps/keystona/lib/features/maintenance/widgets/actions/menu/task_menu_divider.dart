import 'package:flutter/material.dart';

import '../../../../../core/theme/aurora_colors.dart';
import '../../../../../core/theme/aurora_sizes.dart';

/// The hairline between menu rows.
class TaskMenuDivider extends StatelessWidget {
  const TaskMenuDivider({super.key});

  @override
  Widget build(BuildContext context) => const Divider(
    height: AuroraBorders.hairline,
    thickness: AuroraBorders.hairline,
    color: AuroraColors.inkBorder,
  );
}
