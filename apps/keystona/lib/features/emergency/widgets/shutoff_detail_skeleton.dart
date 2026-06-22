import 'package:flutter/material.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';

/// Pulse-shimmer skeleton matching the shutoff detail form layout.
class ShutoffDetailSkeleton extends StatefulWidget {
  const ShutoffDetailSkeleton({super.key});

  @override
  State<ShutoffDetailSkeleton> createState() => _ShutoffDetailSkeletonState();
}

class _ShutoffDetailSkeletonState extends State<ShutoffDetailSkeleton>
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
              const SizedBox(height: AuroraSpacing.space3),

              _SectionLabelBar(),
              const SizedBox(height: AuroraSpacing.space3),
              const _FieldBar(),
              const SizedBox(height: AuroraSpacing.space3),
              const _FieldBar(),
              const SizedBox(height: AuroraSpacing.space9),

              _SectionLabelBar(),
              const SizedBox(height: AuroraSpacing.space3),
              const _FieldBar(),
              const SizedBox(height: AuroraSpacing.space3),
              const _FieldBar(),
              const SizedBox(height: AuroraSpacing.space9),

              _SectionLabelBar(),
              const SizedBox(height: AuroraSpacing.space3),
              const _MultilineBar(),
              const SizedBox(height: AuroraSpacing.space9),

              _SectionLabelBar(),
              const SizedBox(height: AuroraSpacing.space3),
              const _MultilineBar(),

              const Spacer(),

              const _SaveButtonBar(),
              const SizedBox(height: AuroraSpacing.space7),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabelBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const _SkeletonBar(height: 13, widthFraction: 0.35);
  }
}

class _FieldBar extends StatelessWidget {
  const _FieldBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AuroraColors.ink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AuroraColors.inkBorder),
      ),
    );
  }
}

class _MultilineBar extends StatelessWidget {
  const _MultilineBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: AuroraColors.ink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AuroraColors.inkBorder),
      ),
    );
  }
}

class _SaveButtonBar extends StatelessWidget {
  const _SaveButtonBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AuroraColors.ink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.height, required this.widthFraction});
  final double height;
  final double widthFraction;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFraction,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AuroraColors.ink.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
