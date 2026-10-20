import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../home_lifespan_copy.dart';
import '../../home_profile_format.dart';
import '../../lifespan/home_lifespan_data.dart';
import '../../lifespan/timeline_axis.dart';
import '../../models/item_ref.dart';
import 'lifespan_set_aside.dart';
import 'lifespan_summary.dart';
import 'lifespan_tabs.dart';
import 'lifespan_timeline.dart';

/// HomeLifespan once the items have loaded: summary, tabs, the timeline and
/// the set-aside table. [tab] is 0 for all, 1 for systems, 2 for appliances.
class LifespanContent extends StatelessWidget {
  const LifespanContent({
    super.key,
    required this.data,
    required this.tab,
    required this.onTab,
    required this.onOpen,
  });

  final HomeLifespanData data;
  final int tab;
  final ValueChanged<int> onTab;
  final ValueChanged<ItemRef> onOpen;

  /// Tab index to item kind: 0 all, 1 systems, 2 appliances.
  static ItemKind? kindFor(int tab) => switch (tab) {
    1 => ItemKind.system,
    2 => ItemKind.appliance,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final kind = kindFor(tab);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: a.of(AuroraSpacing.space8),
      children: [
        LifespanSummary(
          eyebrow: HomeLifespanCopy.eyebrow(data.items.length),
          title: HomeLifespanCopy.title,
          total: HomeFormat.money(data.forecastFor(kind).total),
          totalSub: HomeLifespanCopy.totalSub,
          footnote: HomeLifespanCopy.footnote,
        ),
        LifespanTabs(
          labels: [
            HomeLifespanCopy.tabAll(data.items.length),
            HomeLifespanCopy.tabSystems,
            HomeLifespanCopy.tabAppliances,
          ],
          selected: tab,
          onChanged: onTab,
        ),
        LifespanTimeline(
          axis: TimelineAxis(data.now),
          items: data.forKind(kind),
          firstYear: data.forecast.firstYear,
          onOpen: onOpen,
        ),
        LifespanSetAside(forecast: data.forecast),
      ],
    );
  }
}
