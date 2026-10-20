import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_b.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_chip.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// One way to add a document: icon tile, title, one line of help, chevron.
///
/// [highlight] is the single coral tile in the sheet (Smart scan); [badge]
/// adds a coral pill after the title.
class UploadSourceRow extends StatelessWidget {
  const UploadSourceRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.highlight = false,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;
  final bool highlight;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: title,
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraUploadSizes.sourceIconTile),
        ),
        padding: a.symmetric(vertical: AuroraSpacing.space5),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(
                  top: BorderSide(
                    color: AuroraColors.inkBorder,
                    width: AuroraBorders.hairline,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            _IconTile(icon: icon, highlight: highlight),
            SizedBox(width: a.of(AuroraSpacing.space6)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: a.of(AuroraSpacing.space2),
                    runSpacing: a.of(AuroraSpacing.space1),
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        title,
                        style: AuroraType.sheetTitle.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (badge != null)
                        StatusChip(
                          label: badge!,
                          background: AuroraColors.coral,
                          foreground: AuroraColors.paper,
                        ),
                    ],
                  ),
                  SizedBox(height: a.of(AuroraSpacing.space1)),
                  Text(
                    subtitle,
                    style: AuroraType.body.copyWith(
                      color: AuroraColors.inkBody,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space3)),
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

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.highlight});

  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final side = a.of(AuroraUploadSizes.sourceIconTile);
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        color: highlight ? AuroraColors.coral : AuroraColors.paper,
        borderRadius: AuroraRadius.md,
        border: highlight
            ? null
            : Border.all(
                color: AuroraColors.inkTileBorder,
                width: AuroraBorders.regular,
              ),
      ),
      child: Icon(
        icon,
        size: a.of(AuroraIconSizes.lg),
        color: highlight ? AuroraColors.paper : AuroraColors.ink,
      ),
    );
  }
}
