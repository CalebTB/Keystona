import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_chip.dart';
import '../../home_lifespan_copy.dart';
import '../../lifespan/lifespan_forecast.dart';
import 'set_aside_table.dart';

/// "WHAT TO SET ASIDE" with the PREMIUM tag, the five-year table and the
/// monthly footnote.
class LifespanSetAside extends StatelessWidget {
  const LifespanSetAside({super.key, required this.forecast});

  final LifespanForecast forecast;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(HomeLifespanCopy.setAside, style: AuroraType.label),
            ),
            SizedBox(width: a.of(AuroraSpacing.space3)),
            const StatusChip.overdue(label: HomeLifespanCopy.premium),
          ],
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        SetAsideTable(forecast: forecast),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        Text(HomeLifespanCopy.monthly(forecast), style: AuroraType.helper),
      ],
    );
  }
}
