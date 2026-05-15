import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_sizes.dart';

/// Shimmer skeleton for the curated photo grid.
///
/// 6 tiles, alternating square and tall aspect ratios, matching the
/// [PhotosCuratedGrid] layout so the loading → content transition is seamless.
class PhotosGridSkeleton extends StatefulWidget {
  const PhotosGridSkeleton({super.key});

  @override
  State<PhotosGridSkeleton> createState() => _PhotosGridSkeletonState();
}

class _PhotosGridSkeletonState extends State<PhotosGridSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = Tween<double>(begin: 0.3, end: 0.7).animate(_ctrl);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, _) => Opacity(
        opacity: _opacity.value,
        child: Padding(
          padding: AppPadding.screen,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemCount: 6,
            itemBuilder: (_, index) {
              // Every 3rd tile (index % 3 == 2) is tall.
              final isTall = index % 3 == 2;
              return AspectRatio(
                aspectRatio: isTall ? 0.72 : 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
