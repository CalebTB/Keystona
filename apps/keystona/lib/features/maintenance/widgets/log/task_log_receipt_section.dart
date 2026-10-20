import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_b.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../models/task_log_draft.dart';
import '../shared/task_section_label.dart';

/// "Receipt": the documents linked as receipts, each removable, and a row to
/// link another from Docs.
class TaskLogReceiptSection extends StatelessWidget {
  const TaskLogReceiptSection({
    super.key,
    required this.receipts,
    required this.onAdd,
    required this.onRemove,
  });

  final List<ReceiptOption> receipts;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraSpacing.space3));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TaskSectionLabel(title: 'Receipt'),
        gap,
        for (final r in receipts) ...[
          _ReceiptRow(receipt: r, onRemove: () => onRemove(r.id)),
          gap,
        ],
        _AddRow(onTap: onAdd, first: receipts.isEmpty),
      ],
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.receipt, required this.onRemove});

  final ReceiptOption receipt;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      padding: EdgeInsets.only(
        left: a.of(AuroraSpacing.space6),
        top: a.of(AuroraSpacing.space4),
        bottom: a.of(AuroraSpacing.space4),
      ),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.lg,
        border: Border.all(
          color: AuroraColors.inkBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: a.of(AuroraTasksB.logTile),
            height: a.of(AuroraTasksB.logTile),
            decoration: BoxDecoration(
              borderRadius: AuroraRadius.tile,
              border: Border.all(
                color: AuroraColors.olive,
                width: AuroraBorders.regular,
              ),
            ),
            child: ExcludeSemantics(
              child: Icon(
                Icons.receipt_long_outlined,
                size: a.of(AuroraIconSizes.md),
                color: AuroraColors.olive,
              ),
            ),
          ),
          SizedBox(width: a.of(AuroraSpacing.space5)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receipt.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AuroraTasksBType.itemTitle,
                ),
                SizedBox(height: a.of(AuroraTasksB.hairlineGap)),
                Text(
                  'Linked from Docs'.toUpperCase(),
                  style: AuroraType.meta.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AuroraColors.olive,
                  ),
                ),
              ],
            ),
          ),
          AuroraPressable(
            onTap: onRemove,
            semanticLabel: 'Remove receipt',
            enforceTouchTarget: true,
            child: Icon(
              Icons.close,
              size: a.of(AuroraIconSizes.md),
              color: AuroraColors.inkHelper,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddRow extends StatelessWidget {
  const _AddRow({required this.onTap, required this.first});

  final VoidCallback onTap;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final label = first ? 'Add a receipt' : 'Add another receipt';
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraSizes.minTouch),
        ),
        padding: a.symmetric(
          horizontal: AuroraSpacing.space6,
          vertical: AuroraSpacing.space4,
        ),
        decoration: BoxDecoration(
          borderRadius: AuroraRadius.lg,
          border: Border.all(
            color: AuroraColors.inkBorder,
            width: AuroraBorders.regular,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.add,
              size: a.of(AuroraIconSizes.md),
              color: AuroraColors.inkSecondary,
            ),
            SizedBox(width: a.of(AuroraSpacing.space5)),
            Expanded(child: Text(label, style: AuroraTasksBType.itemTitle)),
            Icon(
              Icons.chevron_right,
              size: a.of(AuroraIconSizes.sm),
              color: AuroraColors.inkPlaceholder,
            ),
          ],
        ),
      ),
    );
  }
}
