import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_b.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';

/// Marks a field smart scan filled in: a cobalt rule down its left edge,
/// clipped to the field's corners. Draws nothing extra when [active] is false.
class UploadScanEdge extends StatelessWidget {
  const UploadScanEdge({
    super.key,
    required this.active,
    required this.child,
    this.borderRadius = AuroraRadius.md,
  });

  final bool active;
  final Widget child;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    final a = context.aurora;
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  width: a.of(AuroraUploadSizes.scanRule),
                  color: AuroraColors.cobalt,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
