import 'package:flutter/material.dart';

import '../../../../../core/theme/aurora_colors.dart';
import '../../../../../core/theme/aurora_docs_b.dart';
import '../../../../../core/theme/aurora_radius.dart';
import '../../../../../core/theme/aurora_scale.dart';
import '../../../../../core/theme/aurora_spacing.dart';
import '../../../../../core/theme/aurora_typography.dart';

/// "Edges found — hold still" or "Move closer · fill the frame".
class CameraHintPill extends StatelessWidget {
  const CameraHintPill({super.key, required this.ready});

  final bool ready;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: a.symmetric(
          horizontal: AuroraSpacing.space6,
          vertical: AuroraSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: ready ? AuroraColors.lime : AuroraCameraColors.hintIdleFill,
          borderRadius: AuroraRadius.full,
        ),
        child: Text(
          ready ? 'Edges found — hold still' : 'Move closer · fill the frame',
          textAlign: TextAlign.center,
          style: AuroraType.bodyLg.copyWith(
            fontWeight: FontWeight.w600,
            color: ready ? AuroraColors.oliveDeep : AuroraColors.paper,
          ),
        ),
      ),
    );
  }
}
