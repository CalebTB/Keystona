import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_b.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../models/scan_prefill.dart';
import '../../systems_copy.dart';

/// The System | Appliance switch over the camera.
class ScanKindSwitch extends StatelessWidget {
  const ScanKindSwitch({super.key, required this.kind, required this.onChanged});

  final ScanKind kind;
  final ValueChanged<ScanKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      padding: a.all(AuroraSpacing.space1),
      decoration: const BoxDecoration(
        color: AuroraHomeBColors.cameraChip,
        borderRadius: AuroraRadius.full,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final k in ScanKind.values)
            Flexible(
              child: AuroraPressable(
                onTap: () => onChanged(k),
                selected: k == kind,
                semanticLabel: _label(k),
                enforceTouchTarget: true,
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: a.minControl(AuroraSizes.minTouch),
                  ),
                  padding: a.symmetric(horizontal: AuroraSpacing.space8),
                  decoration: BoxDecoration(
                    color: k == kind ? AuroraColors.paper : null,
                    borderRadius: AuroraRadius.full,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _label(k),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AuroraType.button.copyWith(
                      color: k == kind
                          ? AuroraColors.ink
                          : AuroraHomeBColors.cameraTextSoft,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _label(ScanKind k) => k == ScanKind.system
      ? SystemsCopy.scanSegmentSystem
      : SystemsCopy.scanSegmentAppliance;
}
