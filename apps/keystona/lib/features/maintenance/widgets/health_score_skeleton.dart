import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';

/// Pulse-shimmer skeleton that matches [HealthScoreWidget]'s layout exactly.
///
/// Height: 104px (same as the real widget's card height).
/// Left: circular gauge placeholder · Right: four stat lines.
class HealthScoreSkeleton extends StatefulWidget {
  const HealthScoreSkeleton({super.key});

  @override
  State<HealthScoreSkeleton> createState() => _HealthScoreSkeletonState();
}

class _HealthScoreSkeletonState extends State<HealthScoreSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 0.7).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPadding.screenHorizontal.copyWith(
        top: AppSizes.sm,
        bottom: AppSizes.sm,
      ),
      child: AnimatedBuilder(
        animation: _opacity,
        builder: (_, _) => Opacity(
          opacity: _opacity.value,
          child: Container(
            height: 104,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              children: [
                // Circular gauge placeholder.
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                // Stats lines.
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Bar(width: 0.5),
                      const SizedBox(height: AppSizes.xs),
                      _Bar(width: 0.75),
                      const SizedBox(height: AppSizes.sm),
                      Row(
                        children: [
                          Expanded(child: _Bar(width: 1.0)),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(child: _Bar(width: 1.0)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) => Container(
        width: constraints.maxWidth * width,
        height: 10,
        decoration: BoxDecoration(
          color: AppColors.gray200,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
      ),
    );
  }
}
