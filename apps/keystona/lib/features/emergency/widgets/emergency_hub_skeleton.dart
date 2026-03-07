import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';

/// Pulse-shimmer skeleton matching the Emergency Hub main screen layout:
///   - Three utility shutoff cards (Water / Gas / Electrical)
///   - Contacts section header + two contact rows
///   - Insurance section header + one policy row
class EmergencyHubSkeleton extends StatefulWidget {
  const EmergencyHubSkeleton({super.key});

  @override
  State<EmergencyHubSkeleton> createState() => _EmergencyHubSkeletonState();
}

class _EmergencyHubSkeletonState extends State<EmergencyHubSkeleton>
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
    // Defer repeat() until after the first frame to avoid scheduling a frame
    // during an in-progress navigation transition (debugFrameWasSentToEngine).
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
              // Utility shutoffs section.
              _SectionHeaderSkeleton(),
              const SizedBox(height: AppSizes.sm),
              _ShutoffCardSkeleton(),
              const SizedBox(height: AppSizes.sm),
              _ShutoffCardSkeleton(),
              const SizedBox(height: AppSizes.sm),
              _ShutoffCardSkeleton(),
              const SizedBox(height: AppSizes.lg),

              // Contacts section.
              _SectionHeaderSkeleton(),
              const SizedBox(height: AppSizes.sm),
              _ContactRowSkeleton(),
              const SizedBox(height: AppSizes.sm),
              _ContactRowSkeleton(),
              const SizedBox(height: AppSizes.lg),

              // Insurance section.
              _SectionHeaderSkeleton(),
              const SizedBox(height: AppSizes.sm),
              _PolicyRowSkeleton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeaderSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Bar(width: 120, height: 14);
  }
}

class _ShutoffCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSizes.md),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Bar(width: 100, height: 11),
                const SizedBox(height: 6),
                _Bar(width: 160, height: 9),
              ],
            ),
          ),
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

class _ContactRowSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Bar(width: 120, height: 11),
                const SizedBox(height: 5),
                _Bar(width: 80, height: 9),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyRowSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Bar(width: 100, height: 11),
                const SizedBox(height: 5),
                _Bar(width: 140, height: 9),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
    );
  }
}
