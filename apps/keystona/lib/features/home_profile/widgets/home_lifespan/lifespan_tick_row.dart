import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_a.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../home_lifespan_copy.dart';
import '../../lifespan/timeline_axis.dart';

/// The years above the timeline (decade ticks) and the TODAY tag, placed on
/// the same axis the item bars use.
class LifespanTickRow extends StatelessWidget {
  const LifespanTickRow({super.key, required this.axis});

  final TimelineAxis axis;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final height = a.of(AuroraHomeASizes.tickRow) * a.textScale.clamp(1.0, 2.0);
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, box) => Stack(
            children: [
              for (final year in axis.ticks)
                _At(
                  x: axis.x(year.toDouble()) * box.maxWidth,
                  child: Text('$year', style: AuroraHomeAType.tick),
                ),
              _At(
                x: axis.nowX * box.maxWidth,
                child: Container(
                  padding: a.symmetric(horizontal: AuroraSpacing.space1),
                  decoration: const BoxDecoration(
                    color: AuroraColors.ink,
                    borderRadius: AuroraRadius.xs,
                  ),
                  child: Text(
                    HomeLifespanCopy.today,
                    style: AuroraHomeAType.todayTag,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Centers [child] on [x] from the left edge.
class _At extends StatelessWidget {
  const _At({required this.x, required this.child});

  final double x;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: 0,
      child: FractionalTranslation(
        translation: const Offset(-0.5, 0),
        child: child,
      ),
    );
  }
}
