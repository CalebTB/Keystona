import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_a.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../models/tasks_year_data.dart';
import '../../tasks_copy.dart';
import 'year_chart_column.dart';

/// "YOUR YEAR": twelve month columns (count, bar, letter) with season captions
/// under them. Tapping a column selects that month.
class YearChart extends StatelessWidget {
  const YearChart({
    super.key,
    required this.data,
    required this.selected,
    required this.onSelect,
  });

  final TasksYearData data;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final max = data.maxCount;
    return Container(
      padding: EdgeInsets.fromLTRB(
        a.of(AuroraSpacing.space4),
        a.of(AuroraSpacing.space6),
        a.of(AuroraSpacing.space4),
        a.of(AuroraSpacing.space3),
      ),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.banner,
        border: Border.all(
          color: AuroraColors.inkBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: a.of(AuroraSpacing.space1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(TasksCopy.yourYear, style: AuroraType.label),
                ),
                Flexible(
                  child: Text(
                    data.range,
                    textAlign: TextAlign.end,
                    style: AuroraType.meta.copyWith(
                      color: AuroraColors.inkHelper,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: a.of(AuroraSpacing.space4)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < data.months.length; i++)
                Expanded(
                  child: YearChartColumn(
                    month: data.months[i].month,
                    count: data.months[i].count,
                    fraction: max == 0 ? 0 : data.months[i].count / max,
                    selected: i == selected,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
          const Divider(
            height: AuroraBorders.hairline,
            thickness: AuroraBorders.hairline,
            color: AuroraColors.inkBorder,
          ),
          SizedBox(height: a.of(AuroraSpacing.space2)),
          Row(
            children: [
              for (
                var i = 0;
                i < data.months.length;
                i += AuroraTasksA.monthsPerSeason
              )
                Expanded(
                  flex: AuroraTasksA.monthsPerSeason,
                  child: Text(
                    TasksCopy.season(data.months[i].month),
                    textAlign: TextAlign.center,
                    style: AuroraTasksAType.season,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
