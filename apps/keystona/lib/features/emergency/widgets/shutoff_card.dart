import 'package:flutter/material.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../models/utility_shutoff.dart';
import '../../../core/theme/aurora_radius.dart';

/// Card showing a single utility shutoff's setup status.
class ShutoffCard extends StatelessWidget {
  const ShutoffCard({
    super.key,
    required this.utilityType,
    required this.shutoff,
    required this.onTap,
  });

  /// 'water', 'gas', or 'electrical'
  final String utilityType;
  final UtilityShutoff? shutoff;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isComplete = shutoff?.isComplete ?? false;
    final isSetUp = shutoff != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AuroraColors.paper,
          borderRadius: AuroraRadius.md,
          border: Border.all(
            color: isComplete ? AuroraColors.limeDeep : AuroraColors.inkBorder,
          ),
        ),
        padding: const EdgeInsets.all(AuroraSpacing.space7),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconBg(isComplete),
                borderRadius: AuroraRadius.sm,
              ),
              child: Icon(
                _icon,
                size: 22,
                color: _iconColor(isComplete),
              ),
            ),
            const SizedBox(width: AuroraSpacing.space7),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    utilityType.utilityLabel,
                    style: AuroraType.body.copyWith(fontWeight: FontWeight.w600, color: AuroraColors.ink),
                  ),
                  if (isSetUp) ...[
                    const SizedBox(height: 2),
                    Text(
                      shutoff!.locationDescription,
                      style: AuroraType.bodySm.copyWith(
                        color: AuroraColors.inkSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else ...[
                    const SizedBox(height: 2),
                    Text(
                      'Tap to set up',
                      style: AuroraType.bodySm.copyWith(
                        color: AuroraColors.inkSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AuroraSpacing.space3),

            _StatusBadge(isComplete: isComplete, isSetUp: isSetUp),
            const SizedBox(width: AuroraSpacing.space1),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AuroraColors.inkSecondary,
            ),
          ],
        ),
      ),
    );
  }

  IconData get _icon => switch (utilityType) {
        'water' => Icons.water_drop_outlined,
        'gas' => Icons.local_fire_department_outlined,
        'electrical' => Icons.electric_bolt_outlined,
        _ => Icons.settings_outlined,
      };

  Color _iconBg(bool complete) => complete
      ? AuroraColors.limeDeep.withValues(alpha: 0.12)
      : AuroraColors.ink.withValues(alpha: 0.08);

  Color _iconColor(bool complete) =>
      complete ? AuroraColors.limeDeep : AuroraColors.ink;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isComplete, required this.isSetUp});
  final bool isComplete;
  final bool isSetUp;

  @override
  Widget build(BuildContext context) {
    if (!isSetUp) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AuroraColors.butter,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          'Not set up',
          style: AuroraType.bodySm.copyWith(
            fontSize: 10,
            color: AuroraColors.inkSecondary,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isComplete
            ? AuroraColors.limeDeep.withValues(alpha: 0.12)
            : AuroraColors.yellowDeep.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        isComplete ? 'Complete' : 'Incomplete',
        style: AuroraType.bodySm.copyWith(
          fontSize: 10,
          color: isComplete ? AuroraColors.limeDeep : AuroraColors.yellowDeep,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
