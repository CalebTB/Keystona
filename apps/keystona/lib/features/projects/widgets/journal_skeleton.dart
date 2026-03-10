import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';

/// Pulse-shimmer skeleton matching [JournalNoteCard] layout.
///
/// Shows 3 placeholder note cards: date header bar + title bar + content bars.
/// Uses addPostFrameCallback to start animation safely on all route types.
class JournalSkeleton extends StatefulWidget {
  const JournalSkeleton({super.key});

  @override
  State<JournalSkeleton> createState() => _JournalSkeletonState();
}

class _JournalSkeletonState extends State<JournalSkeleton>
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
            _SkeletonNoteCard(),
            SizedBox(height: AppSizes.sm),
            _SkeletonNoteCard(),
            SizedBox(height: AppSizes.sm),
            _SkeletonNoteCard(),
          ],
        ),
      ),
    );
  }
}

class _SkeletonNoteCard extends StatelessWidget {
  const _SkeletonNoteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header bar.
          FractionallySizedBox(
            widthFactor: 0.3,
            alignment: Alignment.centerLeft,
            child: Container(height: 11, color: AppColors.gray200),
          ),
          const SizedBox(height: AppSizes.sm),
          // Title bar.
          FractionallySizedBox(
            widthFactor: 0.55,
            alignment: Alignment.centerLeft,
            child: Container(height: 15, color: AppColors.gray200),
          ),
          const SizedBox(height: AppSizes.xs),
          // Content line 1.
          Container(height: 12, color: AppColors.gray200),
          const SizedBox(height: 4),
          // Content line 2.
          FractionallySizedBox(
            widthFactor: 0.8,
            alignment: Alignment.centerLeft,
            child: Container(height: 12, color: AppColors.gray200),
          ),
          const SizedBox(height: 4),
          // Content line 3.
          FractionallySizedBox(
            widthFactor: 0.6,
            alignment: Alignment.centerLeft,
            child: Container(height: 12, color: AppColors.gray200),
          ),
        ],
      ),
    );
  }
}
