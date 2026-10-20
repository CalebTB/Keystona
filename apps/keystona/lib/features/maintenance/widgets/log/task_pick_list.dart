import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_button.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../../../core/widgets/loading_skeleton_card.dart';

/// One row in a [TaskPickList].
class TaskPickItem {
  const TaskPickItem({required this.title, this.subtitle});

  final String title;
  final String? subtitle;
}

/// The body of a pick-one sheet: rows to tap, with loading, error and empty
/// states. It does not know what it lists; callers map their data to
/// [TaskPickItem]s.
class TaskPickList extends StatelessWidget {
  const TaskPickList({
    super.key,
    required this.items,
    required this.emptyText,
    required this.onPick,
    required this.onRetry,
  });

  /// Loading, error or the rows.
  final AsyncValue<List<TaskPickItem>> items;
  final String emptyText;

  /// Called with the index of the tapped row.
  final ValueChanged<int> onPick;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final rows = items.value;
    if (rows != null) {
      if (rows.isEmpty) {
        return Text(emptyText, style: AuroraTasksBType.entryMeta);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(
                height: AuroraBorders.hairline,
                thickness: AuroraBorders.hairline,
                color: AuroraColors.inkBorder,
              ),
            _Row(item: rows[i], onTap: () => onPick(i)),
          ],
        ],
      );
    }
    if (items.hasError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Couldn't load the list.", style: AuroraTasksBType.entryMeta),
          SizedBox(height: a.of(AuroraSpacing.space5)),
          SecondaryButton(label: 'Try again', onPressed: onRetry),
        ],
      );
    }
    return Column(
      children: [
        for (var i = 0; i < AuroraTasksB.pickSkeletonRows; i++) ...[
          if (i > 0) SizedBox(height: a.of(AuroraSpacing.space3)),
          LoadingSkeletonCard(height: a.of(AuroraTasksB.skelRow)),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item, required this.onTap});

  final TaskPickItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: item.title,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraSizes.actionRow),
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.title, style: AuroraTasksBType.itemTitle),
              if (item.subtitle != null) ...[
                SizedBox(height: a.of(AuroraTasksB.hairlineGap)),
                Text(item.subtitle!.toUpperCase(), style: AuroraType.meta),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
