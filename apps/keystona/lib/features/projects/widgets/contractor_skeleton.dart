import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';

/// Shimmer skeleton for the contractors list.
class ContractorSkeleton extends StatefulWidget {
  const ContractorSkeleton({super.key});

  @override
  State<ContractorSkeleton> createState() => _ContractorSkeletonState();
}

class _ContractorSkeletonState extends State<ContractorSkeleton>
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
        child: ListView.separated(
          padding: AppPadding.screen,
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
          itemBuilder: (_, _) => Container(
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm,
            ),
            child: Row(
              children: [
                // Avatar circle.
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gray300,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FractionallySizedBox(
                        widthFactor: 0.5,
                        child: Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.gray300,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusSm),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      FractionallySizedBox(
                        widthFactor: 0.35,
                        child: Container(
                          height: 11,
                          decoration: BoxDecoration(
                            color: AppColors.gray300,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusSm),
                          ),
                        ),
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
