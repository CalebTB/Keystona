import 'package:flutter/material.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_radius.dart';

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
      builder: (_, _) => Opacity(
        opacity: _opacity.value,
        child: const Padding(
          padding: EdgeInsets.all(AuroraSpacing.screenPadH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PolicyCardSkeleton(),
              SizedBox(height: AuroraSpacing.space3),
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
        color: AuroraColors.paper,
        borderRadius: AuroraRadius.md,
        border: Border.all(color: AuroraColors.inkBorder),
      ),
      padding: const EdgeInsets.all(AuroraSpacing.space7),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(width: 40, height: 40, radius: 8),
          SizedBox(width: AuroraSpacing.space7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FractionallySizedBox(
                  widthFactor: 0.55,
                  alignment: Alignment.centerLeft,
                  child: _SkeletonBox(height: 11, radius: 8),
                ),
                SizedBox(height: 6),
                FractionallySizedBox(
                  widthFactor: 0.40,
                  alignment: Alignment.centerLeft,
                  child: _SkeletonBox(height: 9, radius: 8),
                ),
                SizedBox(height: 6),
                FractionallySizedBox(
                  widthFactor: 0.70,
                  alignment: Alignment.centerLeft,
                  child: _SkeletonBox(height: 9, radius: 8),
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
        color: AuroraColors.ink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
