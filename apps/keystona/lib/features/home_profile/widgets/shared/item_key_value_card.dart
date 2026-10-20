import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_home_shared.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import 'item_key_value.dart';
import 'item_row_group.dart';

/// A card of label / value rows: the label at the left in tracked mono, the
/// value at the right. A [ItemKeyValue.copyable] row carries a copy icon.
class ItemKeyValueCard extends StatefulWidget {
  const ItemKeyValueCard({super.key, required this.rows});

  final List<ItemKeyValue> rows;

  @override
  State<ItemKeyValueCard> createState() => _ItemKeyValueCardState();
}

class _ItemKeyValueCardState extends State<ItemKeyValueCard> {
  Timer? _timer;
  int? _copiedRow;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _copy(int index) async {
    await Clipboard.setData(ClipboardData(text: widget.rows[index].value));
    if (!mounted) return;
    setState(() => _copiedRow = index);
    _timer?.cancel();
    _timer = Timer(AuroraHomeDurations.copied, () {
      if (mounted) setState(() => _copiedRow = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ItemRowGroup(
      children: [
        for (var i = 0; i < widget.rows.length; i++)
          _Row(
            row: widget.rows[i],
            copied: _copiedRow == i,
            onCopy: () => _copy(i),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.row, required this.copied, required this.onCopy});

  final ItemKeyValue row;
  final bool copied;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: a.of(AuroraHomeSizes.rowMin)),
      child: Padding(
        padding: EdgeInsets.only(
          left: a.of(AuroraSpacing.space6),
          right: a.of(row.copyable ? AuroraSpacing.space2 : AuroraSpacing.space6),
          top: row.copyable ? 0 : a.of(AuroraSpacing.space5),
          bottom: row.copyable ? 0 : a.of(AuroraSpacing.space5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(row.label.toUpperCase(), style: AuroraType.label),
            SizedBox(width: a.of(AuroraSpacing.space5)),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      row.value,
                      textAlign: TextAlign.end,
                      style: AuroraHomeType.keyValue,
                    ),
                  ),
                  if (row.copyable)
                    AuroraPressable(
                      onTap: onCopy,
                      semanticLabel: 'Copy ${row.label.toLowerCase()}',
                      enforceTouchTarget: true,
                      child: Padding(
                        padding: a.all(AuroraSpacing.space3),
                        child: copied
                            ? Text(
                                'COPIED',
                                style: AuroraHomeType.tag.copyWith(
                                  color: AuroraColors.olive,
                                ),
                              )
                            : Icon(
                                Icons.content_copy_outlined,
                                size: a.of(AuroraIconSizes.sm),
                                color: AuroraColors.inkSecondary,
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
