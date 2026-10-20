import 'package:flutter/material.dart';

import '../../../maintenance/widgets/reminders/reminders_back_link.dart';
import '../../systems_copy.dart';
import 'outlined_add_pill.dart';

/// "‹ Home profile" at the left, the outlined "+ Add" pill at the right.
class SystemsTopBar extends StatelessWidget {
  const SystemsTopBar({super.key, required this.onBack, required this.onAdd});

  final VoidCallback onBack;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: RemindersBackLink(label: SystemsCopy.homeBack, onTap: onBack),
        ),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: OutlinedAddPill(
              label: SystemsCopy.add,
              semanticLabel: SystemsCopy.addSemantics,
              onTap: onAdd,
            ),
          ),
        ),
      ],
    );
  }
}
