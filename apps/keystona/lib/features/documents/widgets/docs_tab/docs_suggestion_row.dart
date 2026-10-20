import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_a.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// One "start with these" row: icon, title, "CATEGORY · WHY" and an outlined
/// plus. Tapping anywhere adds that kind of document.
class DocsSuggestionRow extends StatelessWidget {
  const DocsSuggestionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.meta,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: title,
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraDocsA.rowMinHeight),
        ),
        padding: a.symmetric(
          horizontal: AuroraSpacing.space6,
          vertical: AuroraSpacing.space5,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: a.of(AuroraIconSizes.md),
              color: AuroraColors.inkSubtle,
            ),
            SizedBox(width: a.of(AuroraSpacing.space5)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AuroraType.rowTitle),
                  SizedBox(height: a.of(AuroraDocsA.hairlineGap)),
                  Text(meta, style: AuroraType.meta),
                ],
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space5)),
            _PlusCircle(),
          ],
        ),
      ),
    );
  }
}

class _PlusCircle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      width: a.of(AuroraDocsA.plusCircle),
      height: a.of(AuroraDocsA.plusCircle),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AuroraColors.inkTileBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Icon(
        Icons.add,
        size: a.of(AuroraIconSizes.sm),
        color: AuroraColors.ink,
      ),
    );
  }
}
