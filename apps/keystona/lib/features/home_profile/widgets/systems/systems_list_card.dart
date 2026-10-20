import 'package:flutter/material.dart';

import '../../models/systems_list_view.dart';
import '../../models/system_reading.dart';
import '../../systems_copy.dart';
import '../shared/item_list_row.dart';
import '../shared/item_row_group.dart';
import 'system_icons.dart';

/// The list card: one `ItemListRow` per system.
class SystemsListCard extends StatelessWidget {
  const SystemsListCard({
    super.key,
    required this.items,
    required this.taskCount,
    required this.onOpen,
  });

  final List<SystemListItem> items;

  /// Open tasks for a system id.
  final int Function(String id) taskCount;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return ItemRowGroup(
      children: [
        for (final item in items)
          ItemListRow(
            key: ValueKey(item.system.id),
            icon: SystemIcons.forCategory(item.system.category),
            name: item.system.name,
            subtitle: item.system.subtitle,
            reading: item.reading,
            warrantyNote: item.warrantyEndsOn == null
                ? null
                : SystemsCopy.warrantyNote(item.warrantyEndsOn!),
            taskCount: taskCount(item.system.id),
            onTap: () => onOpen(item.system.id),
          ),
      ],
    );
  }
}
