import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_b.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';

/// The status line under the frame: what to do, "reading", or what was found
/// (lime).
class ScanHintPill extends StatelessWidget {
  const ScanHintPill({
    super.key,
    required this.text,
    this.found = false,
    this.busy = false,
  });

  final String text;
  final bool found;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: a.symmetric(
          horizontal: AuroraSpacing.space7,
          vertical: AuroraSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: found ? AuroraColors.lime : AuroraHomeBColors.cameraChip,
          borderRadius: AuroraRadius.full,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy) ...[
              SizedBox.square(
                dimension: a.of(AuroraSizes.spinner),
                child: const CircularProgressIndicator(
                  strokeWidth: AuroraBorders.spinnerStroke,
                  valueColor: AlwaysStoppedAnimation(AuroraColors.paper),
                ),
              ),
              SizedBox(width: a.of(AuroraSpacing.space3)),
            ],
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: AuroraHomeBSizes.hintMaxLines,
                overflow: TextOverflow.ellipsis,
                style: AuroraType.button.copyWith(
                  color: found ? AuroraColors.oliveDeep : AuroraColors.paper,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
