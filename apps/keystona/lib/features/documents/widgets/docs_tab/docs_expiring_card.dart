import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_a.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_button.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../docs_copy.dart';
import '../../models/category_icons.dart';
import '../../models/docs_expiry.dart';
import '../../models/docs_tab_data.dart';
import '../docs_button_row.dart';

/// The one coral-outlined card on the Docs tab: the document that needs
/// action first, with Upload renewal / Remind me and a line for the next one.
class DocsExpiringCard extends StatelessWidget {
  const DocsExpiringCard({
    super.key,
    required this.item,
    required this.onUploadRenewal,
    required this.onRemind,
    this.more = 0,
    this.next,
    this.onOpenNext,
  });

  final DocsTabItem item;

  /// How many more documents expire soon after [item].
  final int more;

  /// The one after [item], named on the "N more" line.
  final DocsTabItem? next;

  final VoidCallback onUploadRenewal;
  final VoidCallback onRemind;
  final VoidCallback? onOpenNext;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final expiry = DocsExpiry.of(item.expirationDate!);
    return Container(
      padding: a.all(AuroraSpacing.space7),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.banner,
        border: Border.all(
          color: AuroraColors.coral,
          width: AuroraBorders.emphasis,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _IconTile(iconKey: item.categoryIcon),
              Flexible(child: StatusBadge.overdue(DocsCopy.daysLeft(expiry))),
            ],
          ),
          SizedBox(height: a.of(AuroraSpacing.space5)),
          Text(item.name, style: AuroraDocsAType.heroTitle),
          SizedBox(height: a.of(AuroraSpacing.space2)),
          Text(
            DocsCopy.expiringBody(
              categoryName: item.categoryName,
              date: item.expirationDate!,
            ),
            style: AuroraDocsAType.heroBody,
          ),
          SizedBox(height: a.of(AuroraSpacing.space5)),
          Text(
            DocsCopy.addedMeta(item.categoryName, item.createdAt),
            style: AuroraType.meta,
          ),
          SizedBox(height: a.of(AuroraSpacing.space5)),
          DocsButtonRow(
            primary: PrimaryButton(
              label: DocsCopy.uploadRenewal,
              onPressed: onUploadRenewal,
              expand: true,
            ),
            secondary: SecondaryButton(
              label: DocsCopy.remindMe,
              onPressed: onRemind,
            ),
          ),
          if (next != null && more > 0) ...[
            SizedBox(height: a.of(AuroraSpacing.space5)),
            const Divider(
              height: AuroraBorders.hairline,
              thickness: AuroraBorders.hairline,
              color: AuroraColors.inkBorder,
            ),
            _MoreLine(
              text: DocsCopy.moreLine(more, next!.name, next!.expirationDate!),
              onTap: onOpenNext,
            ),
          ],
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.iconKey});

  final String? iconKey;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      width: a.of(AuroraSharedSizes.iconTile),
      height: a.of(AuroraSharedSizes.iconTile),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.md,
        border: Border.all(
          color: AuroraColors.inkTileBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Icon(
        CategoryIcons.forKey(iconKey ?? CategoryIcons.defaultKey),
        size: a.of(AuroraIconSizes.md),
        color: AuroraColors.ink,
      ),
    );
  }
}

class _MoreLine extends StatelessWidget {
  const _MoreLine({required this.text, required this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: text,
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraSizes.minTouch),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AuroraDocsAType.link,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: a.of(AuroraIconSizes.sm),
              color: AuroraColors.inkCheckBorder,
            ),
          ],
        ),
      ),
    );
  }
}
