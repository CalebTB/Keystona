import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';

/// Pulse-shimmer skeleton matching [PhaseCard] layout.
///
/// Uses addPostFrameCallback per the lesson:
/// "addPostFrameCallback is required in ALL skeleton initState methods".
class PhaseListSkeleton extends StatefulWidget {
  const PhaseListSkeleton({super.key});

  @override
  State<PhaseListSkeleton> createState() => _PhaseListSkeletonState();
}

class _PhaseListSkeletonState extends State<PhaseListSkeleton>
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
            _SkeletonPhaseCard(),
            SizedBox(height: AppSizes.sm),
            _SkeletonPhaseCard(),
            SizedBox(height: AppSizes.sm),
            _SkeletonPhaseCard(),
          ],
        ),
      ),
    );
  }
}

class _SkeletonPhaseCard extends StatelessWidget {
  const _SkeletonPhaseCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: AppSizes.cardMinHeight),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          // Drag handle column.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 14, height: 14, color: AppColors.gray200),
              const SizedBox(height: 4),
              Container(width: 14, height: 14, color: AppColors.gray200),
            ],
          ),
          const SizedBox(width: AppSizes.md),
          // Name + description column.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(
                  widthFactor: 0.55,
                  alignment: Alignment.centerLeft,
                  child: Container(height: 16, color: AppColors.gray200),
                ),
                const SizedBox(height: AppSizes.xs),
                FractionallySizedBox(
                  widthFactor: 0.8,
                  alignment: Alignment.centerLeft,
                  child: Container(height: 12, color: AppColors.gray200),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          // Status badge placeholder.
          Container(
            width: 72,
            height: 24,
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
