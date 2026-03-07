import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';

/// Pulse-shimmer skeleton matching the shutoff detail form layout.
///
/// Mirrors the field groups rendered by [ShutoffDetailScreen]:
///   - Nav bar title area
///   - "General" section: location + special instructions bars
///   - Utility-specific section: two additional field bars
///   - Tools section: a multi-line bar
///   - Save button bar at bottom
///
/// Displayed on frame 1 while [EmergencyHubNotifier.getShutoff()] resolves.
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
    // Defer repeat() until after the first frame to avoid scheduling a frame
    // during an in-progress navigation transition.
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
              const SizedBox(height: AppSizes.sm),

              // ── General section ─────────────────────────────────────────
              _SectionLabelBar(),
              const SizedBox(height: AppSizes.sm),
              _FieldBar(),
              const SizedBox(height: AppSizes.sm),
              _FieldBar(),
              const SizedBox(height: AppSizes.lg),

              // ── Utility-specific section ────────────────────────────────
              _SectionLabelBar(),
              const SizedBox(height: AppSizes.sm),
              _FieldBar(),
              const SizedBox(height: AppSizes.sm),
              _FieldBar(),
              const SizedBox(height: AppSizes.lg),

              // ── Tools section ───────────────────────────────────────────
              _SectionLabelBar(),
              const SizedBox(height: AppSizes.sm),
              _MultilineBar(),
              const SizedBox(height: AppSizes.lg),

              // ── Special instructions ────────────────────────────────────
              _SectionLabelBar(),
              const SizedBox(height: AppSizes.sm),
              _MultilineBar(),

              const Spacer(),

              // ── Save button ─────────────────────────────────────────────
              _SaveButtonBar(),
              const SizedBox(height: AppSizes.md),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Private skeleton primitives ───────────────────────────────────────────────

class _SectionLabelBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SkeletonBar(
      height: 13,
      widthFraction: 0.35,
    );
  }
}

class _FieldBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.inputHeight,
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
    );
  }
}

class _MultilineBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
    );
  }
}

class _SaveButtonBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.buttonHeight,
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
    );
  }
}

/// A skeleton bar whose width is a fraction of the available horizontal space.
///
/// Uses [FractionallySizedBox] so bars scale correctly on all screen widths
/// without requiring a [LayoutBuilder] pass.
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
          color: AppColors.gray200,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
      ),
    );
  }
}
