import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_a.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../home_lifespan_copy.dart';
import '../../lifespan/lifespan_forecast.dart';
import '../shared/item_row_group.dart';

/// "What to set aside": a row per forecast year with its bar, what is due and
/// the amount, in one bordered card.
class SetAsideTable extends StatelessWidget {
  const SetAsideTable({super.key, required this.forecast});

  final LifespanForecast forecast;

  @override
  Widget build(BuildContext context) {
    return ItemRowGroup(
      children: [
        for (final year in forecast.years)
          _YearRow(year: year, peak: forecast.peak),
      ],
    );
  }
}

class _YearRow extends StatelessWidget {
  const _YearRow({required this.year, required this.peak});

  final ForecastYear year;
  final double peak;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Padding(
      padding: a.symmetric(
        horizontal: AuroraSpacing.space6,
        vertical: AuroraSpacing.space5,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: a.of(AuroraHomeASizes.yearColumn),
            child: Text('${year.year}', style: AuroraHomeAType.setAsideYear),
          ),
          SizedBox(width: a.of(AuroraSpacing.space5)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Bar(fraction: year.amount / peak),
                SizedBox(height: a.of(AuroraSpacing.space2)),
                Text(HomeLifespanCopy.whatNames(year), style: AuroraType.meta),
              ],
            ),
          ),
          SizedBox(width: a.of(AuroraSpacing.space5)),
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: a.of(AuroraHomeASizes.amountMin),
            ),
            child: Text(
              HomeLifespanCopy.amount(year),
              textAlign: TextAlign.end,
              style: AuroraHomeAType.setAsideAmount,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return ExcludeSemantics(
      child: SizedBox(
        height: a.of(AuroraHomeASizes.inlineBar),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: AuroraRadius.xs,
            border: Border.all(
              color: AuroraColors.inkBorder,
              width: AuroraBorders.regular,
            ),
          ),
          child: ClipRRect(
            borderRadius: AuroraRadius.xs,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fraction.clamp(0.0, 1.0),
                heightFactor: 1,
                child: const ColoredBox(color: AuroraColors.ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
