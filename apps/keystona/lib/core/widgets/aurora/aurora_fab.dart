import 'package:flutter/material.dart';

import '../../theme/aurora_colors.dart';
import '../../theme/aurora_shadows.dart';

/// Aurora floating action button — coral, 56×56, circular, with coral glow.
///
/// On iOS, embed in a `Stack + Positioned(bottom: 24, right: 24)` since
/// `CupertinoPageScaffold` has no floatingActionButton slot.
class AuroraFAB extends StatelessWidget {
  const AuroraFAB({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Tooltip(
        message: tooltip ?? '',
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AuroraColors.coral,
            shape: BoxShape.circle,
            boxShadow: AuroraShadows.fab,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
