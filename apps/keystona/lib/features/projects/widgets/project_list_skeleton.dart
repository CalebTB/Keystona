import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';

/// Pulse-shimmer skeleton matching [ProjectCard] layout.
///
/// Shows 3 placeholder cards: cover photo thumb + name + status chip +
/// budget row + date row.
class ProjectListSkeleton extends StatefulWidget {
  const ProjectListSkeleton({super.key});

  @override
  State<ProjectListSkeleton> createState() => _ProjectListSkeletonState();
}

class _ProjectListSkeletonState extends State<ProjectListSkeleton>
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
            _SkeletonCard(),
            SizedBox(height: AppSizes.sm),
            _SkeletonCard(),
            SizedBox(height: AppSizes.sm),
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover photo placeholder.
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSizes.radiusMd),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + status chip row.
                Row(
                  children: [
                    Expanded(
                      child: FractionallySizedBox(
                        widthFactor: 0.55,
                        alignment: Alignment.centerLeft,
                        child: Container(height: 16, color: AppColors.gray200),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.gray200,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),
                // Budget row.
                FractionallySizedBox(
                  widthFactor: 0.45,
                  alignment: Alignment.centerLeft,
                  child: Container(height: 12, color: AppColors.gray200),
                ),
                const SizedBox(height: AppSizes.xs),
                // Date row.
                FractionallySizedBox(
                  widthFactor: 0.35,
                  alignment: Alignment.centerLeft,
                  child: Container(height: 12, color: AppColors.gray200),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
