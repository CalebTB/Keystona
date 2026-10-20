import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_b.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../systems_copy.dart';

/// EXPECTED LIFESPAN: the label with "15 years" at the right, the slider, and
/// the help line.
class LifespanSlider extends StatelessWidget {
  const LifespanSlider({
    super.key,
    required this.years,
    required this.help,
    required this.onChanged,
  });

  final int years;
  final String help;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                SystemsCopy.expectedLifespan.toUpperCase(),
                style: AuroraType.label,
              ),
            ),
            Text(SystemsCopy.lifeYears(years), style: AuroraType.number),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: a.of(AuroraHomeBSizes.sliderTrack),
            activeTrackColor: AuroraColors.cobalt,
            inactiveTrackColor: AuroraColors.inkBorder,
            thumbColor: AuroraColors.cobalt,
            overlayColor: AuroraColors.cobaltDim,
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: a.of(AuroraHomeBSizes.sliderThumbRadius),
            ),
          ),
          child: Slider(
            min: AuroraHomeBSizes.sliderMin,
            max: AuroraHomeBSizes.sliderMax,
            divisions:
                (AuroraHomeBSizes.sliderMax - AuroraHomeBSizes.sliderMin)
                    .toInt(),
            value: years.toDouble(),
            semanticFormatterCallback: (v) => SystemsCopy.lifeYears(v.round()),
            label: SystemsCopy.lifeYears(years),
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        SizedBox(height: a.of(AuroraSpacing.space1)),
        Text(help, style: AuroraType.helper),
      ],
    );
  }
}
