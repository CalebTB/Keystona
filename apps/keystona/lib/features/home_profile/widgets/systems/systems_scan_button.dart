import 'package:flutter/material.dart';

import '../../systems_copy.dart';
import '../shared/dashed_action_button.dart';

/// The dashed "Scan a label to add one" button under the list.
class SystemsScanButton extends StatelessWidget {
  const SystemsScanButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DashedActionButton(
    icon: Icons.photo_camera_outlined,
    label: SystemsCopy.scanToAdd,
    onTap: onTap,
  );
}
