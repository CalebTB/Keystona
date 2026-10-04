import 'package:flutter/material.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_radius.dart';

/// Shimmer skeleton for the linked documents list.
class LinkedDocumentsSkeleton extends StatefulWidget {
  const LinkedDocumentsSkeleton({super.key});

  @override
  State<LinkedDocumentsSkeleton> createState() =>
      _LinkedDocumentsSkeletonState();
}

class _LinkedDocumentsSkeletonState
    extends State<LinkedDocumentsSkeleton>
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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0DFEA),
                    borderRadius:
                        AuroraRadius.sm,
                  ),
                ),
                const SizedBox(width: AuroraSpacing.space7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FractionallySizedBox(
                        widthFactor: 0.6,
                        child: Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0DFEA),
                            borderRadius: AuroraRadius.sm,
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
                            borderRadius: AuroraRadius.sm,
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
