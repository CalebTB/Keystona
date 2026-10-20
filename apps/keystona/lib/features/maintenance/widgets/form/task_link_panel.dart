import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_c.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../models/task_link_option.dart';
import '../../task_form_copy.dart';
import 'task_choice_grid.dart';

/// The picker that opens under the linked item field: Systems / Appliances
/// segments and the items of the chosen kind, each with a radio.
class TaskLinkPanel extends StatelessWidget {
  const TaskLinkPanel({
    super.key,
    required this.options,
    required this.kind,
    required this.selectedId,
    required this.onKind,
    required this.onPick,
  });

  final List<TaskLinkOption> options;
  final TaskLinkKind kind;
  final String? selectedId;
  final ValueChanged<TaskLinkKind> onKind;
  final ValueChanged<TaskLinkOption> onPick;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final systems = options.where((o) => o.kind == TaskLinkKind.system).length;
    final appliances = options.length - systems;
    final items = options.where((o) => o.kind == kind).toList();
    return Container(
      padding: a.all(AuroraSpacing.space4),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.lg,
        border: Border.all(
          color: AuroraColors.inkBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TaskChoiceGrid<TaskLinkKind>(
            choices: [
              TaskChoice(
                value: TaskLinkKind.system,
                label: '${TaskFormCopy.systemsTab} · $systems',
              ),
              TaskChoice(
                value: TaskLinkKind.appliance,
                label: '${TaskFormCopy.appliancesTab} · $appliances',
              ),
            ],
            selected: kind,
            onSelect: onKind,
            minHeight: AuroraTasksCSizes.segmentMinHeight,
            labelStyle: AuroraTasksCType.choice,
            radius: AuroraRadius.tile,
          ),
          SizedBox(height: a.of(AuroraSpacing.space3)),
          if (items.isEmpty)
            Padding(
              padding: a.symmetric(vertical: AuroraSpacing.space5),
              child: Text(
                TaskFormCopy.nothingToPick,
                textAlign: TextAlign.center,
                style: AuroraType.body.copyWith(
                  color: AuroraColors.inkSecondary,
                ),
              ),
            ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Divider(
                height: AuroraBorders.hairline,
                thickness: AuroraBorders.hairline,
                color: AuroraColors.inkBorder,
              ),
            _ItemRow(
              item: items[i],
              on: items[i].id == selectedId,
              onTap: () => onPick(items[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.on, required this.onTap});

  final TaskLinkOption item;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      selected: on,
      semanticLabel: item.name,
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraTasksCSizes.pickerRowMinHeight),
        ),
        padding: a.symmetric(
          horizontal: AuroraSpacing.space2,
          vertical: AuroraSpacing.space2,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    style: AuroraType.h3.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: a.of(AuroraSpacing.space1)),
                  Text(item.listMeta, style: AuroraType.meta),
                ],
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space5)),
            _Radio(on: on),
          ],
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      width: a.of(AuroraTasksCSizes.radio),
      height: a.of(AuroraTasksCSizes.radio),
      decoration: BoxDecoration(
        color: on ? AuroraColors.ink : AuroraColors.paper,
        shape: BoxShape.circle,
        border: Border.all(
          color: on ? AuroraColors.ink : AuroraColors.inkCheckBorder,
          width: AuroraBorders.emphasis,
        ),
      ),
      child: on
          ? Icon(
              Icons.check,
              size: a.of(AuroraTasksCSizes.radioCheck),
              color: AuroraColors.paper,
            )
          : null,
    );
  }
}
