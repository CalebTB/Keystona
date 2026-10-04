import 'package:flutter/material.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_radius.dart';




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
          padding: EdgeInsets.symmetric(horizontal: AuroraSpacing.screenPadH),
          children: const [
            _SkeletonCard(),
            SizedBox(height: AuroraSpacing.space3),
            _SkeletonCard(),
            SizedBox(height: AuroraSpacing.space3),
            _SkeletonCard(),
            SizedBox(height: AuroraSpacing.space3),
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
      padding: const EdgeInsets.all(AuroraSpacing.space5),
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: AuroraRadius.lg,
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
                  child: Container(height: 14, color: AuroraColors.inkBorder),
                ),
              ),
              Container(
                width: 72,
                height: 22,
                decoration: BoxDecoration(
                  color: AuroraColors.inkBorder,
                  borderRadius: AuroraRadius.full,
                ),
              ),
            ],
          ),
          const SizedBox(height: AuroraSpacing.space3),
          // Progress bar.
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AuroraColors.inkBorder,
              borderRadius: AuroraRadius.full,
            ),
          ),
          const SizedBox(height: AuroraSpacing.space3),
          // Age / years remaining row.
          Row(
            children: [
              Container(width: 80, height: 11, color: AuroraColors.inkBorder),
              const Spacer(),
              Container(width: 64, height: 11, color: AuroraColors.inkBorder),
            ],
          ),
        ],
      ),
    );
  }
}
