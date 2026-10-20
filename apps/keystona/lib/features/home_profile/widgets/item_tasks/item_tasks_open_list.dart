import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../maintenance/widgets/actions/task_menu.dart';
import '../../../maintenance/widgets/actions/task_quick_done.dart';
import '../../models/item_tasks.dart';
import '../shared/dashed_action_button.dart';
import 'item_open_task_card.dart';

/// The "Coming up" tab: a card per open task and the dashed "Add a furnace
/// task" button. A tap opens the task, the circle marks it done, a long press
/// opens the task menu (Skip, Change how often, Open, Stop reminding me).
class ItemTasksOpenList extends ConsumerWidget {
  const ItemTasksOpenList({
    super.key,
    required this.cards,
    required this.addLabel,
    required this.onAdd,
  });

  final List<ItemTaskCard> cards;
  final String addLabel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final card in cards) ...[
          ItemOpenTaskCard(
            key: ValueKey(card.task.id),
            card: card,
            onToggle: () => TaskQuickDone.run(context, ref, card.task),
            onOpen: () => context.push(
              AppRoutes.maintenanceTaskDetail.replaceFirst(
                ':taskId',
                card.task.id,
              ),
            ),
            onMenu: () => TaskMenu.show(context, ref, card.task),
          ),
          SizedBox(height: a.of(AuroraSpacing.space4)),
        ],
        SizedBox(height: a.of(AuroraSpacing.space3)),
        DashedActionButton(
          icon: Icons.add,
          label: addLabel,
          onTap: onAdd,
        ),
      ],
    );
  }
}
