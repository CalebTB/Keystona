import 'package:flutter/material.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_radius.dart';




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
          padding: EdgeInsets.symmetric(horizontal: AuroraSpacing.screenPadH),
          child: Column(
            children: [
              const _SkeletonCard(),
              const SizedBox(height: AuroraSpacing.space3),
              const _SkeletonCard(),
              const SizedBox(height: AuroraSpacing.space3),
              const _SkeletonCard(),
              const SizedBox(height: AuroraSpacing.space3),
              const _SkeletonCard(),
              const SizedBox(height: AuroraSpacing.space3),
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
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.space5,
        vertical: AuroraSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: AuroraRadius.lg,
        border: Border.all(color: AuroraColors.inkBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AuroraColors.inkBorder,
              borderRadius: AuroraRadius.sm,
            ),
          ),
          const SizedBox(width: AuroraSpacing.space5),
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
                      color: AuroraColors.inkBorder,
                      borderRadius: AuroraRadius.sm,
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
                      color: AuroraColors.inkBorder,
                      borderRadius: AuroraRadius.sm,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AuroraSpacing.space3),
          Container(
            width: 56,
            height: 22,
            decoration: BoxDecoration(
              color: AuroraColors.inkBorder,
              borderRadius: AuroraRadius.full,
            ),
          ),
        ],
      ),
    );
  }
}
