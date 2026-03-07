import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';

class ApplianceListSkeleton extends StatefulWidget {
  const ApplianceListSkeleton({super.key});

  @override
  State<ApplianceListSkeleton> createState() => _ApplianceListSkeletonState();
}

class _ApplianceListSkeletonState extends State<ApplianceListSkeleton>
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
      builder: (context, _) => Opacity(
        opacity: _opacity.value,
        child: Padding(
          padding: AppPadding.screen,
          child: Column(
            children: [
              const _SkeletonCard(),
              const SizedBox(height: AppSizes.sm),
              const _SkeletonCard(),
              const SizedBox(height: AppSizes.sm),
              const _SkeletonCard(),
              const SizedBox(height: AppSizes.sm),
              const _SkeletonCard(),
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
      constraints: const BoxConstraints(minHeight: AppSizes.cardMinHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.6,
                  child: Container(
                    height: 13,
                    decoration: BoxDecoration(
                      color: AppColors.gray200,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.4,
                  child: Container(
                    height: 11,
                    decoration: BoxDecoration(
                      color: AppColors.gray200,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Container(
            width: 56,
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
