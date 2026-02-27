import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';

/// Shimmer placeholder card shown while content is loading.
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

  /// Corner radius. Defaults to [AppSizes.radiusMd] (12px).
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.gray200,
      highlightColor: AppColors.gray100,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: AppColors.gray200,
          borderRadius: borderRadius ?? BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),
    );
  }
}
