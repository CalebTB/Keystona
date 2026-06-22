import 'package:flutter/material.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';

/// Pulse-shimmer skeleton matching the Emergency Hub main screen layout.
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
          padding: const EdgeInsets.all(AuroraSpacing.screenPadH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeaderSkeleton(),
              const SizedBox(height: AuroraSpacing.space3),
              const _ShutoffCardSkeleton(),
              const SizedBox(height: AuroraSpacing.space3),
              const _ShutoffCardSkeleton(),
              const SizedBox(height: AuroraSpacing.space3),
              const _ShutoffCardSkeleton(),
              const SizedBox(height: AuroraSpacing.space9),

              _SectionHeaderSkeleton(),
              const SizedBox(height: AuroraSpacing.space3),
              const _ContactRowSkeleton(),
              const SizedBox(height: AuroraSpacing.space3),
              const _ContactRowSkeleton(),
              const SizedBox(height: AuroraSpacing.space9),

              _SectionHeaderSkeleton(),
              const SizedBox(height: AuroraSpacing.space3),
              const _PolicyRowSkeleton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeaderSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const _Bar(width: 120, height: 14);
}

class _ShutoffCardSkeleton extends StatelessWidget {
  const _ShutoffCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AuroraColors.inkBorder),
      ),
      padding: const EdgeInsets.all(AuroraSpacing.space7),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AuroraColors.ink.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: AuroraSpacing.space7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _Bar(width: 100, height: 11),
                const SizedBox(height: 6),
                const _Bar(width: 160, height: 9),
              ],
            ),
          ),
          Container(
            width: 72,
            height: 24,
            decoration: BoxDecoration(
              color: AuroraColors.ink.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRowSkeleton extends StatelessWidget {
  const _ContactRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AuroraColors.inkBorder),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.space7,
        vertical: AuroraSpacing.space3,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AuroraColors.ink.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AuroraSpacing.space7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _Bar(width: 120, height: 11),
                const SizedBox(height: 5),
                const _Bar(width: 80, height: 9),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AuroraColors.ink.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyRowSkeleton extends StatelessWidget {
  const _PolicyRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AuroraColors.inkBorder),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.space7,
        vertical: AuroraSpacing.space3,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AuroraColors.ink.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: AuroraSpacing.space7),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Bar(width: 100, height: 11),
                SizedBox(height: 5),
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
        color: AuroraColors.ink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
