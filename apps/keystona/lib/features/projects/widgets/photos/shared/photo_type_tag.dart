import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../../../core/theme/aurora_colors.dart';
import '../../../../../core/theme/aurora_typography.dart';
import '../../../../../core/theme/aurora_radius.dart';


/// Colored badge shown at the top-left of each photo tile.
///
/// Uses a backdrop blur so the badge reads well over any image content.
/// AuroraType.labelSm (mono 9px/600), paper text.
class PhotoTypeTag extends StatelessWidget {
  const PhotoTypeTag({super.key, required this.photoType});

  final String photoType;

  static final Map<String, Color> _colors = {
    'before':      AuroraColors.cobalt.withValues(alpha: 0.5),
    'after':       AuroraColors.lime.withValues(alpha: 0.5),
    'progress':    AuroraColors.yellow.withValues(alpha: 0.5),
    'inspiration': AuroraColors.cobalt.withValues(alpha: 0.5),
    'issue':       AuroraColors.coral.withValues(alpha: 0.9),
  };

  static final Color _fallback = const Color(0xFF9D9BB0).withValues(alpha: 0.5);

  String get _label {
    if (photoType.isEmpty) return photoType;
    return photoType[0].toUpperCase() + photoType.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _colors[photoType] ?? _fallback;

    return ClipRRect(
      borderRadius: AuroraRadius.xs,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          color: bgColor,
          child: Text(
            _label,
            style: AuroraType.labelSm.copyWith(color: AuroraColors.paper, height: 1.2),
          ),
        ),
      ),
    );
  }
}
