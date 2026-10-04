import 'package:flutter/material.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/theme/aurora_radius.dart';

/// Spring maintenance tip card shown below the agenda on the Tasks screen.
class TipCard extends StatelessWidget {
  const TipCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AuroraColors.limeDim,
        borderRadius: AuroraRadius.md,
        border: Border.all(color: AuroraColors.limeDeep.withValues(alpha: 0.10), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spring maintenance tip',
                  style: AuroraType.label.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AuroraColors.limeDeep,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'After the last frost, check outdoor faucets for leaks from '
                  'winter freeze damage before regular use.',
                  style: AuroraType.label.copyWith(
                    color: AuroraColors.inkSecondary,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
