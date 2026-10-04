import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/aurora_colors.dart';
import '../theme/aurora_radius.dart';

/// Shimmer placeholder card shown while content is loading.
///
/// Aurora spec: butter base color, white highlight shimmer (0 → 0.4 → 0),
/// 1.2s duration, default 16px radius (AuroraRadius.xl).
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

  /// Height of the placeholder box.
  final double height;

  /// Optional explicit width. Defaults to `double.infinity` (full-width).
  final double? width;

  /// Corner radius. Defaults to AuroraRadius.xl (16px).
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AuroraRadius.xl;
    return Shimmer(
      gradient: const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          AuroraColors.butter,
          Color(0x66FFFFFF), // white at 0.40 opacity
          AuroraColors.butter,
        ],
        stops: [0.0, 0.5, 1.0],
      ),
      period: const Duration(milliseconds: 1200),
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: AuroraColors.butter,
          borderRadius: radius,
        ),
      ),
    );
  }
}
