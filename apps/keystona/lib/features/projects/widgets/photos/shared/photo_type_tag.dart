import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../../../core/theme/aurora_colors.dart';


/// Colored badge shown at the top-left of each photo tile.
///
/// Uses a backdrop blur so the badge reads well over any image content.
/// IBM Plex Mono 8.5px/700/0.6px tracking, white text.
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
      borderRadius: const BorderRadius.all(Radius.circular(4)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          color: bgColor,
          child: Text(
            _label,
            style: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
