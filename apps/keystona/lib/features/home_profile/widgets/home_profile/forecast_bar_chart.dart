import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_a.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../home_profile_copy.dart';
import '../../lifespan/lifespan_forecast.dart';

/// The five-year bar chart: one column per year with the amount above, the
/// bar scaled to the largest year and the year below. Empty years show a
/// short outlined stub and a dash.
class ForecastBarChart extends StatelessWidget {
  const ForecastBarChart({super.key, required this.forecast});

  final LifespanForecast forecast;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final summary = [
      for (final y in forecast.years)
        if (y.amount > 0) '${y.year} ${HomeProfileCopy.chartLabel(y)}',
    ].join(', ');
    return Semantics(
      label: 'Expected replacement costs: $summary',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < forecast.years.length; i++) ...[
              if (i > 0) SizedBox(width: a.of(AuroraSpacing.space3)),
              Expanded(
                child: _Column(year: forecast.years[i], peak: forecast.peak),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({required this.year, required this.peak});

  final ForecastYear year;
  final double peak;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final empty = year.amount <= 0;
    final stub = a.of(AuroraHomeASizes.chartStub);
    final area = a.of(AuroraHomeASizes.chartBars);
    final barHeight = empty ? stub : (area * year.amount / peak).clamp(stub, area).toDouble();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          HomeProfileCopy.chartLabel(year),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AuroraHomeAType.caption.copyWith(
            letterSpacing: 0,
            color: empty ? AuroraColors.inkTertiary : AuroraColors.ink,
          ),
        ),
        SizedBox(height: a.of(AuroraSpacing.space2)),
        SizedBox(
          height: area,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: empty ? null : AuroraColors.ink,
                borderRadius: AuroraRadius.xs,
                border: empty
                    ? Border.all(
                        color: AuroraColors.inkBorderStrong,
                        width: AuroraBorders.regular,
                      )
                    : null,
              ),
            ),
          ),
        ),
        SizedBox(height: a.of(AuroraSpacing.space2)),
        Text('${year.year}', style: AuroraHomeAType.tick),
      ],
    );
  }
}
