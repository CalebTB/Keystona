import 'package:flutter/material.dart';

import '../../../core/theme/aurora_auth.dart';
import '../../../core/theme/aurora_colors.dart';

/// How a grid backdrop fades out.
enum AuthGridFade {
  /// Fully drawn.
  none,

  /// Solid to [AuroraAuthSizes.welcomeGridFadeStart] of the height, then fades
  /// to nothing at the bottom (welcome).
  bottom,

  /// Solid near the centre, fading outward (splash).
  radial,
}

/// The blueprint grid behind splash, welcome and the check-email tile.
class AuthGrid extends StatelessWidget {
  const AuthGrid({
    super.key,
    required this.color,
    required this.cell,
    this.fade = AuthGridFade.none,
  });

  final Color color;

  /// Distance between lines.
  final double cell;

  final AuthGridFade fade;

  @override
  Widget build(BuildContext context) {
    final Widget grid = CustomPaint(
      painter: _GridPainter(color: color, cell: cell),
      child: const SizedBox.expand(),
    );
    final Gradient? mask = switch (fade) {
      AuthGridFade.none => null,
      AuthGridFade.bottom => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AuroraColors.ink,
          AuroraColors.ink,
          AuroraStructure.transparent,
        ],
        stops: [0, AuroraAuthSizes.welcomeGridFadeStart, 1],
      ),
      AuthGridFade.radial => const RadialGradient(
        center: Alignment(0, AuroraAuthSizes.splashFocusY * 2 - 1),
        radius: 1,
        colors: [
          AuroraColors.ink,
          AuroraColors.ink,
          AuroraStructure.transparent,
        ],
        stops: [
          0,
          AuroraAuthSizes.splashGridFadeStart,
          AuroraAuthSizes.splashGridFadeEnd,
        ],
      ),
    };
    return ExcludeSemantics(
      child: mask == null
          ? grid
          : ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => mask.createShader(rect),
              child: grid,
            ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.color, required this.cell});

  final Color color;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = AuroraAuthSizes.gridLine;
    // Lines start one line-width before the edge, as in the kit.
    for (double x = -AuroraAuthSizes.gridLine; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = -AuroraAuthSizes.gridLine; y <= size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.color != color || old.cell != cell;
}
