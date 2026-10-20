import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../home_profile_copy.dart';
import '../../models/home_item.dart';
import '../../models/item_ref.dart';
import '../home_common/home_item_icons.dart';
import '../shared/dashed_action_button.dart';
import '../shared/item_list_row.dart';
import '../shared/item_row_group.dart';
import '../shared/mono_section_label.dart';
import 'around_the_house_row.dart';
import 'profile_pill_row.dart';

/// "SYSTEMS · 5": the most worn systems as compact rows, the two pills to the
/// full lists, and the "Around the house" row.
class ProfileSystemsSection extends StatelessWidget {
  const ProfileSystemsSection({
    super.key,
    required this.systems,
    required this.applianceCount,
    required this.agingCount,
    required this.onOpenSystem,
    required this.onAllSystems,
    required this.onAppliances,
    required this.onScan,
    required this.onAround,
    this.aroundMeta,
  });

  /// Every system, most worn first. Only the first [maxRows] are drawn.
  final List<HomeItem> systems;
  final int applianceCount;
  final int agingCount;
  final ValueChanged<ItemRef> onOpenSystem;
  final VoidCallback onAllSystems;
  final VoidCallback onAppliances;
  final VoidCallback onScan;
  final VoidCallback onAround;
  final String? aroundMeta;

  /// Rows shown before "All systems" takes over.
  static const int maxRows = 5;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraSpacing.space3));
    final shown = systems.take(maxRows).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonoSectionLabel(
          HomeProfileCopy.systemsTitle(systems.length),
          trailing: agingCount > 0 ? HomeProfileCopy.agingCount(agingCount) : null,
          trailingColor: AuroraColors.amberDeep,
        ),
        gap,
        if (shown.isEmpty)
          DashedActionButton(
            icon: Icons.add,
            label: HomeProfileCopy.addByScan,
            onTap: onScan,
          )
        else
          ItemRowGroup(
            children: [
              for (final item in shown)
                ItemListRow(
                  key: ValueKey(item.ref),
                  compact: true,
                  icon: HomeItemIcons.forCategory(item.category),
                  name: item.name,
                  reading: item.reading,
                  onTap: () => onOpenSystem(item.ref),
                ),
            ],
          ),
        gap,
        ProfilePillRow(
          leftLabel: HomeProfileCopy.systemsAll,
          onLeft: onAllSystems,
          rightLabel: HomeProfileCopy.appliancesPill(applianceCount),
          onRight: onAppliances,
        ),
        gap,
        AroundTheHouseRow(onTap: onAround, meta: aroundMeta),
      ],
    );
  }
}
