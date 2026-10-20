import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_b.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../models/category_icons.dart';
import '../../models/document_category.dart';
import 'upload_formatters.dart';

/// One category: icon tile, name, "9 DOCS", and a radio check.
class CategoryPickerRow extends StatelessWidget {
  const CategoryPickerRow({
    super.key,
    required this.category,
    required this.docCount,
    required this.selected,
    required this.onTap,
    this.showDivider = true,
  });

  final DocumentCategory category;
  final int docCount;
  final bool selected;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: category.name,
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraSizes.minTouch),
        ),
        padding: a.symmetric(
          horizontal: AuroraSpacing.space5,
          vertical: AuroraSpacing.space4,
        ),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(
                  bottom: BorderSide(
                    color: AuroraColors.inkBorder,
                    width: AuroraBorders.hairline,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: a.of(AuroraUploadSizes.categoryIconTile),
              height: a.of(AuroraUploadSizes.categoryIconTile),
              decoration: BoxDecoration(
                borderRadius: AuroraRadius.tile,
                border: Border.all(
                  color: AuroraColors.inkTileBorder,
                  width: AuroraBorders.regular,
                ),
              ),
              child: Icon(
                CategoryIcons.forKey(category.icon),
                size: a.of(AuroraIconSizes.sm),
                color: AuroraColors.ink,
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space6)),
            Expanded(
              child: Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AuroraType.sheetTitle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space3)),
            Text(UploadFormatters.docCount(docCount), style: AuroraType.meta),
            SizedBox(width: a.of(AuroraSpacing.space5)),
            _Check(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final side = a.of(AuroraUploadSizes.categoryCheck);
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AuroraColors.cobalt : null,
        border: selected
            ? null
            : Border.all(
                color: AuroraColors.inkBorderStrong,
                width: AuroraBorders.emphasis,
              ),
      ),
      child: selected
          ? Icon(
              Icons.check,
              size: a.of(AuroraIconSizes.xs),
              color: AuroraColors.paper,
            )
          : null,
    );
  }
}
