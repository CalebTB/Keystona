import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';

/// Pulse-shimmer skeleton that matches [LifespanCard] layout.
///
/// Shows 4 placeholder cards (icon + progress bar + 2 text lines + cost).
/// Uses [addPostFrameCallback] to defer [AnimationController.repeat] — safe
/// on both tab-root and pushed-route mounts.
class LifespanSkeleton extends StatefulWidget {
  const LifespanSkeleton({super.key});

  @override
  State<LifespanSkeleton> createState() => _LifespanSkeletonState();
}

class _LifespanSkeletonState extends State<LifespanSkeleton>
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
        child: ListView(
          padding: AppPadding.screen,
          children: const [
            _SkeletonCard(),
            SizedBox(height: AppSizes.sm),
            _SkeletonCard(),
            SizedBox(height: AppSizes.sm),
            _SkeletonCard(),
            SizedBox(height: AppSizes.sm),
            _SkeletonCard(),
          ],
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
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name line + health chip.
          Row(
            children: [
              Expanded(
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  alignment: Alignment.centerLeft,
                  child: Container(height: 14, color: AppColors.gray200),
                ),
              ),
              Container(
                width: 72,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          // Progress bar.
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          // Age / years remaining row.
          Row(
            children: [
              Container(width: 80, height: 11, color: AppColors.gray200),
              const Spacer(),
              Container(width: 64, height: 11, color: AppColors.gray200),
            ],
          ),
        ],
      ),
    );
  }
}
