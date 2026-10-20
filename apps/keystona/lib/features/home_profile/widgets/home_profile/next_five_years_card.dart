import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_home_a.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/aurora/aurora_card.dart';
import '../../home_profile_copy.dart';
import '../../lifespan/lifespan_forecast.dart';
import 'forecast_bar_chart.dart';

/// The "~$4,400 to replace 3 things" card with the five-year chart. Taps to
/// HomeLifespan. With nothing due it says so and draws no chart.
class NextFiveYearsCard extends StatelessWidget {
  const NextFiveYearsCard({
    super.key,
    required this.forecast,
    required this.onTap,
  });

  final LifespanForecast forecast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final nothing = forecast.dueItems.isEmpty;
    return AuroraCard(
      onTap: onTap,
      padding: a.all(AuroraSpacing.space7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: a.of(AuroraSpacing.space2),
            children: [
              Text(
                nothing
                    ? HomeProfileCopy.nothingDueTitle
                    : HomeProfileCopy.totalBig(forecast),
                style: AuroraHomeAType.bigTotal,
              ),
              Text(
                nothing
                    ? HomeProfileCopy.nothingDueSub
                    : HomeProfileCopy.totalSub(forecast),
                style: AuroraHomeAType.bigTotalSub,
              ),
            ],
          ),
          SizedBox(height: a.of(AuroraSpacing.space2)),
          Text(
            nothing
                ? HomeProfileCopy.nothingDueBody
                : HomeProfileCopy.nextFiveBody(forecast),
            style: AuroraHomeAType.summaryBody,
          ),
          if (!nothing) ...[
            SizedBox(height: a.of(AuroraSpacing.space6)),
            ForecastBarChart(forecast: forecast),
          ],
        ],
      ),
    );
  }
}
