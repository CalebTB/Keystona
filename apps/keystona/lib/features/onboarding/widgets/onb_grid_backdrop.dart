import 'package:flutter/material.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_onboarding.dart';

/// Coral grid at the top of the page that fades out downward.
class OnbGridBackdrop extends StatelessWidget {
  const OnbGridBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AuroraColors.ink, AuroraStructure.transparent],
            stops: [AuroraOnbSizes.gridSolidStop, 1],
          ).createShader(bounds),
          child: const SizedBox(
            height: AuroraOnbSizes.gridHeight,
            width: double.infinity,
            child: CustomPaint(painter: _GridPainter()),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AuroraOnbColors.grid
      ..strokeWidth = AuroraOnbSizes.gridLine;
    for (var x = 0.0; x < size.width; x += AuroraOnbSizes.gridCell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += AuroraOnbSizes.gridCell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
