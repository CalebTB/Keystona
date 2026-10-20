import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// Plain ink text action in a top bar ("Edit"), a 44 pt target.
class TaskTextAction extends StatelessWidget {
  const TaskTextAction({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: label,
      enforceTouchTarget: true,
      child: Text(label, style: AuroraType.button),
    );
  }
}
