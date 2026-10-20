import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_a.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../docs_copy.dart';
import '../../models/docs_tab_data.dart';
import '../document_row.dart';

/// "RECENTLY ADDED": the newest documents in one bordered list.
class DocsRecentSection extends StatelessWidget {
  const DocsRecentSection({
    super.key,
    required this.items,
    required this.totalCount,
    required this.onOpen,
    required this.onSeeAll,
  });

  final List<DocsTabItem> items;
  final int totalCount;
  final ValueChanged<DocsTabItem> onOpen;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(DocsCopy.recentHeader, style: AuroraType.label),
            ),
            AuroraPressable(
              onTap: onSeeAll,
              semanticLabel: DocsCopy.seeAll(totalCount),
              enforceTouchTarget: true,
              child: Align(
                alignment: Alignment.centerRight,
                widthFactor: 1,
                child: Text(
                  DocsCopy.seeAll(totalCount),
                  style: AuroraDocsAType.link.copyWith(
                    color: AuroraColors.coral,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: a.of(AuroraSpacing.space1)),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AuroraRadius.xl,
            border: Border.all(
              color: AuroraColors.inkBorder,
              width: AuroraBorders.regular,
            ),
          ),
          child: ClipRRect(
            borderRadius: AuroraRadius.xl,
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: AuroraBorders.hairline,
                      thickness: AuroraBorders.hairline,
                      color: AuroraColors.inkBorder,
                    ),
                  DocumentRow(
                    key: ValueKey(items[i].id),
                    name: items[i].name,
                    meta: DocsCopy.rowMeta(
                      items[i].categoryName,
                      items[i].createdAt,
                    ),
                    expirationDate: items[i].expirationDate,
                    onTap: () => onOpen(items[i]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
