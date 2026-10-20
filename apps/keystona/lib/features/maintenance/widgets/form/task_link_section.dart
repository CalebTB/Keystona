import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_motion.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_c.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_field_chrome.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../models/task_link_option.dart';
import '../../task_form_copy.dart';
import 'task_link_panel.dart';

/// "For which system or appliance": the required field that opens an inline
/// picker, with the line explaining why it is required.
class TaskLinkSection extends StatefulWidget {
  const TaskLinkSection({
    super.key,
    required this.options,
    required this.link,
    required this.onChanged,
  });

  final List<TaskLinkOption> options;
  final TaskLinkOption? link;
  final ValueChanged<TaskLinkOption> onChanged;

  @override
  State<TaskLinkSection> createState() => _TaskLinkSectionState();
}

class _TaskLinkSectionState extends State<TaskLinkSection> {
  bool _open = false;
  TaskLinkKind? _kind;

  TaskLinkKind get _shownKind =>
      _kind ?? widget.link?.kind ?? TaskLinkKind.system;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final link = widget.link;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuroraFieldLabel(label: TaskFormCopy.linkLabel, isRequired: true),
        SizedBox(height: a.of(AuroraSpacing.space2)),
        AuroraPressable(
          onTap: () => setState(() => _open = !_open),
          semanticLabel: link == null
              ? TaskFormCopy.linkLabel
              : '${TaskFormCopy.linkLabel}, ${link.name}',
          child: AuroraFieldBox(
            active: _open,
            padding: a.symmetric(
              horizontal: AuroraSpacing.space6,
              vertical: AuroraSpacing.space3,
            ),
            child: Row(
              children: [
                if (link != null) ...[
                  _Tile(kind: link.kind),
                  SizedBox(width: a.of(AuroraSpacing.space4)),
                ],
                Expanded(
                  child: link == null
                      ? Text(
                          TaskFormCopy.linkPlaceholder,
                          style: AuroraType.input.copyWith(
                            color: AuroraColors.inkPlaceholder,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              link.name,
                              style: AuroraType.h3.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: a.of(AuroraSpacing.space1)),
                            Text(link.fieldMeta, style: AuroraType.meta),
                          ],
                        ),
                ),
                SizedBox(width: a.of(AuroraSpacing.space3)),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: AuroraDurations.fast,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: a.of(AuroraIconSizes.sm),
                    color: AuroraColors.inkHelper,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_open) ...[
          SizedBox(height: a.of(AuroraSpacing.space3)),
          TaskLinkPanel(
            options: widget.options,
            kind: _shownKind,
            selectedId: link?.id,
            onKind: (k) => setState(() => _kind = k),
            onPick: (o) {
              setState(() => _open = false);
              widget.onChanged(o);
            },
          ),
        ],
        SizedBox(height: a.of(AuroraSpacing.space2)),
        Text(TaskFormCopy.linkHelper.toUpperCase(), style: AuroraType.helper),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.kind});

  final TaskLinkKind kind;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      width: a.of(AuroraTasksCSizes.linkTile),
      height: a.of(AuroraTasksCSizes.linkTile),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.tile,
        border: Border.all(
          color: AuroraColors.inkTileBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Icon(
        kind == TaskLinkKind.system
            ? Icons.home_repair_service_outlined
            : Icons.kitchen_outlined,
        size: a.of(AuroraTasksCSizes.linkTileGlyph),
        color: AuroraColors.ink,
      ),
    );
  }
}
