import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';

/// Shimmer skeleton for the photos grid.
class PhotosSkeleton extends StatefulWidget {
  const PhotosSkeleton({super.key});

  @override
  State<PhotosSkeleton> createState() => _PhotosSkeletonState();
}

class _PhotosSkeletonState extends State<PhotosSkeleton>
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
              crossAxisCount: 3,
              mainAxisSpacing: AppSizes.xs,
              crossAxisSpacing: AppSizes.xs,
            ),
            itemCount: 9,
            itemBuilder: (_, _) => Container(
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
