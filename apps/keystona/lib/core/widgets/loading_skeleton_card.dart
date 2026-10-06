import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/aurora_colors.dart';
import '../theme/aurora_motion.dart';
import '../theme/aurora_radius.dart';

/// Shimmer placeholder card shown while content is loading.
///
/// Aurora spec: ink-hairline base (no tinted fill), lighter shimmer band,
/// [AuroraDurations.shimmer] sweep, default 16 px radius (AuroraRadius.xl).
///
/// Matches the visual footprint of real content to minimise layout shift
/// when the actual data resolves. Use feature-specific skeletons that
/// compose multiple [LoadingSkeletonCard] instances for accurate layouts.
class LoadingSkeletonCard extends StatelessWidget {
  const LoadingSkeletonCard({
    super.key,
    required this.height,
    this.width,
    this.borderRadius,
  });

  /// Height of the placeholder box .
  final double height;

  /// Optional explicit width. Defaults to the full available width.
  final double? width;

  /// Corner radius. Defaults to AuroraRadius.xl (16px).
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AuroraRadius.xl;
    return ExcludeSemantics(
      child: Shimmer(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AuroraColors.inkBorder,
            AuroraColors.inkDisabledFill,
            AuroraColors.inkBorder,
          ],
          stops: [0, 0.5, 1],
        ),
        period: AuroraDurations.shimmer,
        child: Container(
          height: height,
          width: width == null ? double.infinity : width!,
          decoration: BoxDecoration(
            color: AuroraColors.inkBorder,
            borderRadius: radius,
          ),
        ),
      ),
    );
  }
}
