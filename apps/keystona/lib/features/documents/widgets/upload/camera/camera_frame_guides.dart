import 'package:flutter/material.dart';

import '../../../../../core/theme/aurora_colors.dart';
import '../../../../../core/theme/aurora_docs_b.dart';
import '../../../../../core/theme/aurora_scale.dart';

/// The four corner guides of the viewfinder. Lime once edges are found, white
/// while the page is still being lined up.
class CameraFrameGuides extends StatelessWidget {
  const CameraFrameGuides({super.key, required this.ready});

  final bool ready;

  @override
  Widget build(BuildContext context) {
    final color = ready ? AuroraColors.lime : AuroraCameraColors.cornerIdle;
    return ExcludeSemantics(
      child: Stack(
        children: [
          for (final corner in _Corner.values)
            Align(
              alignment: corner.alignment,
              child: _CornerGuide(corner: corner, color: color),
            ),
        ],
      ),
    );
  }
}

enum _Corner {
  topLeft(Alignment.topLeft),
  topRight(Alignment.topRight),
  bottomLeft(Alignment.bottomLeft),
  bottomRight(Alignment.bottomRight);

  const _Corner(this.alignment);

  final Alignment alignment;

  bool get top => alignment.y < 0;
  bool get left => alignment.x < 0;
}

class _CornerGuide extends StatelessWidget {
  const _CornerGuide({required this.corner, required this.color});

  final _Corner corner;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final side = BorderSide(
      color: color,
      width: AuroraCameraSizes.cornerStroke,
    );
    const none = BorderSide.none;
    const round = Radius.circular(AuroraCameraSizes.cornerRadius);
    return AnimatedContainer(
      duration: AuroraCameraDurations.cornerFade,
      width: a.of(AuroraCameraSizes.cornerArm),
      height: a.of(AuroraCameraSizes.cornerArm),
      decoration: BoxDecoration(
        border: Border(
          top: corner.top ? side : none,
          bottom: corner.top ? none : side,
          left: corner.left ? side : none,
          right: corner.left ? none : side,
        ),
        borderRadius: BorderRadius.only(
          topLeft: corner.top && corner.left ? round : Radius.zero,
          topRight: corner.top && !corner.left ? round : Radius.zero,
          bottomLeft: !corner.top && corner.left ? round : Radius.zero,
          bottomRight: !corner.top && !corner.left ? round : Radius.zero,
        ),
      ),
    );
  }
}
