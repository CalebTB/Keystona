import 'package:flutter/material.dart';
import '../../../core/theme/aurora_spacing.dart';

/// Shimmer skeleton for the contractors list.
class ContractorSkeleton extends StatefulWidget {
  const ContractorSkeleton({super.key});

  @override
  State<ContractorSkeleton> createState() => _ContractorSkeletonState();
}

class _ContractorSkeletonState extends State<ContractorSkeleton>
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
        child: ListView.separated(
          padding: EdgeInsets.all(AuroraSpacing.screenPadH),
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(height: AuroraSpacing.space3),
          itemBuilder: (_, _) => Container(
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEDF2),
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AuroraSpacing.space7,
              vertical: AuroraSpacing.space3,
            ),
            child: Row(
              children: [
                // Avatar circle.
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE0DFEA),
                  ),
                ),
                const SizedBox(width: AuroraSpacing.space7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FractionallySizedBox(
                        widthFactor: 0.5,
                        child: Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0DFEA),
                            borderRadius:
                                BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      FractionallySizedBox(
                        widthFactor: 0.35,
                        child: Container(
                          height: 11,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0DFEA),
                            borderRadius:
                                BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
