import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_a.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../categories_copy.dart';
import '../../models/category_icons.dart';

/// One custom category: drag handle, icon tile, name, document count, Edit
/// and delete.
class CategoryRow extends StatelessWidget {
  const CategoryRow({
    super.key,
    required this.index,
    required this.name,
    required this.iconKey,
    required this.documentCount,
    required this.onEdit,
    required this.onDelete,
  });

  /// Position in the reorderable list; the drag handle starts a drag for it.
  final int index;
  final String name;
  final String iconKey;
  final int documentCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      constraints: BoxConstraints(
        minHeight: a.minControl(AuroraDocsA.categoryRowMinHeight),
      ),
      padding: EdgeInsets.only(
        left: a.of(AuroraSpacing.space3),
        right: a.of(AuroraSpacing.space2),
        top: a.of(AuroraSpacing.space3),
        bottom: a.of(AuroraSpacing.space3),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Semantics(
              label: CategoriesCopy.dragToReorder,
              child: SizedBox(
                width: a.of(AuroraDocsA.dragHandleWidth),
                height: AuroraSizes.minTouch,
                child: Icon(
                  Icons.drag_indicator,
                  size: a.of(AuroraDocsA.dragGlyph),
                  color: AuroraColors.inkTertiary,
                ),
              ),
            ),
          ),
          SizedBox(width: a.of(AuroraSpacing.space4)),
          _Tile(iconKey: iconKey),
          SizedBox(width: a.of(AuroraSpacing.space5)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AuroraDocsAType.rowName,
                ),
                SizedBox(height: a.of(AuroraDocsA.hairlineGap)),
                Text(
                  CategoriesCopy.documentsCount(documentCount),
                  style: AuroraType.meta,
                ),
              ],
            ),
          ),
          AuroraPressable(
            onTap: onEdit,
            semanticLabel: '${CategoriesCopy.edit} $name',
            enforceTouchTarget: true,
            child: Center(
              widthFactor: 1,
              child: Padding(
                padding: a.symmetric(horizontal: AuroraSpacing.space3),
                child: Text(
                  CategoriesCopy.edit,
                  style: AuroraType.buttonSm.copyWith(
                    color: AuroraColors.cobalt,
                  ),
                ),
              ),
            ),
          ),
          AuroraPressable(
            onTap: onDelete,
            semanticLabel: CategoriesCopy.deleteLabel(name),
            enforceTouchTarget: true,
            child: Center(
              widthFactor: 1,
              child: Icon(
                Icons.delete_outline,
                size: a.of(AuroraIconSizes.lg),
                color: AuroraColors.coralDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.iconKey});

  final String iconKey;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      width: a.of(AuroraDocsA.categoryTile),
      height: a.of(AuroraDocsA.categoryTile),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.tile,
        border: Border.all(
          color: AuroraColors.inkTileBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Icon(
        CategoryIcons.forKey(iconKey),
        size: a.of(AuroraDocsA.categoryGlyph),
        color: AuroraColors.ink,
      ),
    );
  }
}
