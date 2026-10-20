import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_a.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../home_lifespan_copy.dart';

/// Plenty left, last quarter, past expected life: a swatch and a word each,
/// wrapping on narrow screens.
class LifespanLegend extends StatelessWidget {
  const LifespanLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Wrap(
      spacing: a.of(AuroraSpacing.space6),
      runSpacing: a.of(AuroraSpacing.space2),
      children: const [
        _Key(
          label: HomeLifespanCopy.legendPlenty,
          swatch: AuroraColors.cobalt,
          text: AuroraColors.ink,
        ),
        _Key(
          label: HomeLifespanCopy.legendLast,
          swatch: AuroraColors.amber,
          text: AuroraColors.amberDeep,
        ),
        _Key(
          label: HomeLifespanCopy.legendPast,
          swatch: AuroraColors.coral,
          text: AuroraColors.coralDeep,
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.swatch, required this.text});

  final String label;
  final Color swatch;
  final Color text;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: a.of(AuroraHomeASizes.swatchWidth),
          height: a.of(AuroraHomeASizes.swatchHeight),
          decoration: BoxDecoration(
            color: swatch,
            borderRadius: AuroraRadius.xs,
          ),
        ),
        SizedBox(width: a.of(AuroraSpacing.space2)),
        Flexible(
          child: Text(
            label,
            style: AuroraHomeAType.legend.copyWith(color: text),
          ),
        ),
      ],
    );
  }
}
