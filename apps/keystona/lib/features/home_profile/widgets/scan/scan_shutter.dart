import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_b.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../systems_copy.dart';

/// The round shutter button.
class ScanShutter extends StatelessWidget {
  const ScanShutter({super.key, required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final outer = a.of(AuroraHomeBSizes.shutterOuter);
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: SystemsCopy.scanShutter,
      enforceTouchTarget: true,
      child: Container(
        width: outer,
        height: outer,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AuroraColors.paper,
            width: AuroraHomeBSizes.shutterRing,
          ),
        ),
        child: Container(
          width: a.of(AuroraHomeBSizes.shutterInner),
          height: a.of(AuroraHomeBSizes.shutterInner),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AuroraColors.paper,
          ),
        ),
      ),
    );
  }
}
