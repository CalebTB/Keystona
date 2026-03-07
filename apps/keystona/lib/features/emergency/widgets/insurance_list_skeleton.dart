import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';

class InsuranceListSkeleton extends StatefulWidget {
  const InsuranceListSkeleton({super.key});

  @override
  State<InsuranceListSkeleton> createState() => _InsuranceListSkeletonState();
}

class _InsuranceListSkeletonState extends State<InsuranceListSkeleton>
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
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: const Padding(
          padding: AppPadding.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PolicyCardSkeleton(),
              SizedBox(height: AppSizes.sm),
              _PolicyCardSkeleton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PolicyCardSkeleton extends StatelessWidget {
  const _PolicyCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSizes.md),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(width: 40, height: 40, radius: AppSizes.radiusSm),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FractionallySizedBox(
                  widthFactor: 0.55,
                  alignment: Alignment.centerLeft,
                  child: _SkeletonBox(height: 11, radius: AppSizes.radiusSm),
                ),
                SizedBox(height: 6),
                FractionallySizedBox(
                  widthFactor: 0.40,
                  alignment: Alignment.centerLeft,
                  child: _SkeletonBox(height: 9, radius: AppSizes.radiusSm),
                ),
                SizedBox(height: 6),
                FractionallySizedBox(
                  widthFactor: 0.70,
                  alignment: Alignment.centerLeft,
                  child: _SkeletonBox(height: 9, radius: AppSizes.radiusSm),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({this.width, required this.height, required this.radius});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
