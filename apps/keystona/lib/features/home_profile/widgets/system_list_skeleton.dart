import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';

/// Pulse-shimmer skeleton matching the [SystemCard] layout exactly.
///
/// Displayed on the first frame while [SystemsNotifier] resolves.
/// Uses [addPostFrameCallback] to start animation after the first frame
/// and [FractionallySizedBox] for responsive bar widths.
///
/// Layout:
///   - Category section header placeholder
///   - 3 skeleton cards (72px each), icon + two text bars
class SystemListSkeleton extends StatefulWidget {
  const SystemListSkeleton({super.key});

  @override
  State<SystemListSkeleton> createState() => _SystemListSkeletonState();
}

class _SystemListSkeletonState extends State<SystemListSkeleton>
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category header placeholder.
              _Bar(widthFactor: 0.25, height: 12),
              const SizedBox(height: AppSizes.sm),
              const _SkeletonCard(),
              const SizedBox(height: AppSizes.sm),
              const _SkeletonCard(),
              const SizedBox(height: AppSizes.lg),
              _Bar(widthFactor: 0.2, height: 12),
              const SizedBox(height: AppSizes.sm),
              const _SkeletonCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: AppPadding.card,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Category icon placeholder.
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          // Name and type text.
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bar(widthFactor: 0.65, height: 13),
                const SizedBox(height: AppSizes.xs),
                _Bar(widthFactor: 0.45, height: 11),
              ],
            ),
          ),
          // Status chip placeholder.
          Container(
            width: 52,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.widthFactor, required this.height});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.gray200,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
      ),
    );
  }
}
