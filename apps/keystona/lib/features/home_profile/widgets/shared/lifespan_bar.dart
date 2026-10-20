import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_shared.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../lifespan/lifespan_reading.dart';
import 'lifespan_colors.dart';

/// The lifespan bar: a ringed track filled to the percent of life used
/// (capped at the full width), colored by band. [showTick] marks where
/// "aging" starts.
class LifespanBar extends StatelessWidget {
  const LifespanBar({
    super.key,
    required this.reading,
    this.large = false,
    this.showTick = false,
  });

  final LifespanReading reading;

  /// The thicker bar of the detail lifespan card.
  final bool large;
  final bool showTick;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final radius = large ? AuroraRadius.xs : AuroraRadius.bar;
    final percent = reading.percent;
    return Semantics(
      label: percent == null
          ? null
          : '${percent.round()} percent through its expected life',
      child: ExcludeSemantics(
        child: SizedBox(
          height: a.of(
            large ? AuroraHomeSizes.barHeightLg : AuroraHomeSizes.barHeight,
          ),
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: AuroraColors.inkInputBorder,
                width: AuroraBorders.regular,
              ),
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: reading.fraction,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: reading.barColor,
                        borderRadius: radius,
                      ),
                    ),
                  ),
                  if (showTick)
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: AuroraHomeSizes.barTickAt,
                      child: const Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: AuroraBorders.regular,
                          child: ColoredBox(color: AuroraHomeColors.barTick),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
