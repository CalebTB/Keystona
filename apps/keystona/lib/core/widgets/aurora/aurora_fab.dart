import 'package:flutter/material.dart';

import '../../theme/aurora_colors.dart';
import '../../theme/aurora_scale.dart';
import '../../theme/aurora_shadows.dart';
import '../../theme/aurora_sizes.dart';
import 'aurora_pressable.dart';

/// Aurora floating action button — cobalt (an action, not "act now"),
/// circular, with a soft ink lift.
///
/// On iOS, embed in a `Stack + Positioned` at the screen-edge insets since
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
    final a = context.aurora;
    final button = AuroraPressable(
      onTap: onPressed,
      semanticLabel: tooltip,
      child: Container(
        constraints: BoxConstraints.tightFor(
          width: a.of(AuroraSizes.fab),
          height: a.of(AuroraSizes.fab),
        ),
        decoration: BoxDecoration(
          color: AuroraColors.cobalt,
          shape: BoxShape.circle,
          boxShadow: AuroraShadows.fabAction,
        ),
        child: Icon(
          icon,
          color: AuroraColors.paper,
          size: a.of(AuroraIconSizes.xl),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
