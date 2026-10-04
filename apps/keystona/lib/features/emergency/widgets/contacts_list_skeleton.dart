import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_radius.dart';

/// Shimmer loading placeholder matching the [ContactCard] layout.
class ContactsListSkeleton extends StatelessWidget {
  const ContactsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AuroraColors.butter,
      highlightColor: AuroraColors.paper,
      child: ListView(
        padding: const EdgeInsets.all(AuroraSpacing.screenPadH),
        children: const [
          _SkeletonContactCard(),
          SizedBox(height: AuroraSpacing.space3),
          _SkeletonContactCard(),
          SizedBox(height: AuroraSpacing.space3),
          _SkeletonContactCard(),
          SizedBox(height: AuroraSpacing.space3),
          _SkeletonContactCard(),
        ],
      ),
    );
  }
}

class _SkeletonContactCard extends StatelessWidget {
  const _SkeletonContactCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.space7,
        vertical: AuroraSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: AuroraRadius.md,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AuroraColors.butter,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AuroraSpacing.space7),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(
                  widthFactor: 0.55,
                  child: Container(height: 14, color: AuroraColors.butter),
                ),
                const SizedBox(height: 6),
                FractionallySizedBox(
                  widthFactor: 0.38,
                  child: Container(height: 11, color: AuroraColors.butter),
                ),
              ],
            ),
          ),

          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AuroraColors.butter,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AuroraSpacing.space3),

          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AuroraColors.butter,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
