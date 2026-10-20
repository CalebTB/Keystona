import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_c.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_card.dart';
import '../../providers/document_links_provider.dart';

/// One linked item: icon tile, name, kind, chevron.
class DocumentLinkedTile extends StatelessWidget {
  const DocumentLinkedTile({
    super.key,
    required this.entry,
    required this.onTap,
  });

  final DocumentLinkEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final tile = a.of(AuroraSharedSizes.iconTile);
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: a.minControl(AuroraDocsCSizes.linkedRowMinHeight),
      ),
      child: AuroraCard(
        onTap: onTap,
        padding: a.symmetric(
          horizontal: AuroraSpacing.space6,
          vertical: AuroraSpacing.space5,
        ),
        child: Row(
          children: [
            Container(
              width: tile,
              height: tile,
              decoration: BoxDecoration(
                borderRadius: AuroraRadius.md,
                border: Border.all(
                  color: AuroraColors.inkTileBorder,
                  width: AuroraBorders.regular,
                ),
              ),
              child: ExcludeSemantics(
                child: Icon(
                  _icon,
                  size: a.of(AuroraIconSizes.md),
                  color: AuroraColors.ink,
                ),
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space5)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AuroraType.button,
                  ),
                  SizedBox(height: a.of(AuroraSpacing.space1)),
                  Text(_kind, style: AuroraType.meta),
                ],
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space3)),
            Icon(
              CupertinoIcons.chevron_right,
              size: a.of(AuroraIconSizes.sm),
              color: AuroraColors.inkPlaceholder,
            ),
          ],
        ),
      ),
    );
  }

  IconData get _icon => switch (entry.type) {
        DocumentLinkType.project => Icons.folder_outlined,
        DocumentLinkType.appliance => Icons.kitchen_outlined,
        DocumentLinkType.system => Icons.settings_outlined,
      };

  String get _kind => switch (entry.type) {
        DocumentLinkType.project => 'PROJECT',
        DocumentLinkType.appliance => 'APPLIANCE',
        DocumentLinkType.system => 'SYSTEM',
      };
}
