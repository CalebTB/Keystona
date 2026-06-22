import 'package:flutter/material.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';




/// Pulse-shimmer skeleton that matches [HomeProfileScreen]'s card layout.
///
/// Layout mirrors the real screen:
///   - Property card (photo placeholder + 3 text lines)
///   - Two section rows (Systems, Appliances)
class HomeProfileSkeleton extends StatefulWidget {
  const HomeProfileSkeleton({super.key});

  @override
  State<HomeProfileSkeleton> createState() => _HomeProfileSkeletonState();
}

class _HomeProfileSkeletonState extends State<HomeProfileSkeleton>
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
          padding: EdgeInsets.symmetric(horizontal: AuroraSpacing.screenPadH),
          child: Column(
            children: [
              // Property card skeleton.
              _PropertyCardSkeleton(),
              const SizedBox(height: AuroraSpacing.space5),
              // Section rows skeleton.
              _SectionRowSkeleton(),
              const SizedBox(height: AuroraSpacing.space3),
              _SectionRowSkeleton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertyCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AuroraColors.inkBorder),
      ),
      padding: const EdgeInsets.all(AuroraSpacing.space5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo placeholder.
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AuroraColors.inkBorder,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: AuroraSpacing.space5),
          // Text lines.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bar(widthFactor: 0.7),
                const SizedBox(height: AuroraSpacing.space1),
                _Bar(widthFactor: 0.5),
                const SizedBox(height: AuroraSpacing.space1),
                _Bar(widthFactor: 0.4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionRowSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AuroraColors.inkBorder),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.space5,
        vertical: AuroraSpacing.space3,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AuroraColors.inkBorder,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: AuroraSpacing.space5),
          Expanded(child: _Bar(widthFactor: 0.45)),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AuroraColors.inkBorder,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.widthFactor});
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: 10,
        decoration: BoxDecoration(
          color: AuroraColors.inkBorder,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
