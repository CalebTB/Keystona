import 'package:flutter/material.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_radius.dart';

/// Shimmer skeleton for the budget screen while data loads.
class BudgetSkeleton extends StatefulWidget {
  const BudgetSkeleton({super.key});

  @override
  State<BudgetSkeleton> createState() => _BudgetSkeletonState();
}

class _BudgetSkeletonState extends State<BudgetSkeleton>
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

  Widget _bar({double? width, double height = 14}) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFEEEDF2),
          borderRadius: AuroraRadius.sm,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, _) => Opacity(
        opacity: _opacity.value,
        child: ListView(
          padding: EdgeInsets.all(AuroraSpacing.screenPadH),
          children: [
            // Summary header placeholder.
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEDF2),
                borderRadius: AuroraRadius.md,
              ),
            ),
            const SizedBox(height: AuroraSpacing.space7),
            // Category breakdown placeholder.
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEDF2),
                borderRadius: AuroraRadius.md,
              ),
            ),
            const SizedBox(height: AuroraSpacing.space7),
            // 4 line item placeholders.
            ...List.generate(
              4,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: AuroraSpacing.space3),
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEDF2),
                    borderRadius: AuroraRadius.md,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AuroraSpacing.space7,
                    vertical: AuroraSpacing.space3,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FractionallySizedBox(
                              widthFactor: 0.55,
                              child: _bar(height: 13),
                            ),
                            const SizedBox(height: 6),
                            FractionallySizedBox(
                              widthFactor: 0.35,
                              child: _bar(height: 11),
                            ),
                          ],
                        ),
                      ),
                      _bar(width: 60),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
