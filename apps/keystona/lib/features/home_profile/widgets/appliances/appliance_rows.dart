import 'package:flutter/material.dart';

import '../../appliance_copy.dart';
import '../../lifespan/appliance_lifespan.dart';
import '../../models/appliance.dart';
import '../../models/appliance_dates.dart';
import '../../models/item_ref.dart';
import '../../models/appliance_warranty_check.dart';
import '../shared/item_list_row.dart';
import '../shared/item_row_group.dart';
import 'appliance_icons.dart';

/// The bordered card of appliance rows on the Appliances list.
class ApplianceRows extends StatelessWidget {
  const ApplianceRows({
    super.key,
    required this.appliances,
    required this.taskCounts,
    required this.today,
    required this.onOpen,
  });

  final List<Appliance> appliances;

  /// Open tasks per item; an appliance with none reads as 0.
  final Map<ItemRef, int> taskCounts;
  final DateTime today;
  final ValueChanged<String> onOpen;

  /// "Brennan DW24 · Kitchen", or whatever of it is known.
  static String? subtitle(Appliance a) {
    final parts = [
      [a.brand, a.modelNumber]
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .join(' '),
      a.location?.trim() ?? '',
    ].where((s) => s.isNotEmpty);
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return ItemRowGroup(
      children: [
        for (final a in appliances)
          ItemListRow(
            key: ValueKey(a.id),
            icon: ApplianceIcons.forAppliance(a),
            name: a.name,
            subtitle: subtitle(a),
            reading: a.lifespanReading(now: today),
            warrantyNote: _warrantyNote(a),
            taskCount: taskCounts[ItemRef.appliance(a.id)] ?? 0,
            onTap: () => onOpen(a.id),
          ),
      ],
    );
  }

  String? _warrantyNote(Appliance a) {
    final ends = a.warrantyEndsOn;
    return ApplianceWarrantyCheck.endsSoon(ends, today)
        ? ApplianceCopy.warrantyEnds(ends!)
        : null;
  }
}
