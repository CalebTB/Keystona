import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_a.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../docs_copy.dart';

/// The search "field" on the Docs tab. It is a button: tapping it opens the
/// search screen, where typing and the category tags live.
class DocsSearchField extends StatelessWidget {
  const DocsSearchField({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: DocsCopy.searchSemantics,
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraSizes.minTouch),
        ),
        padding: a.symmetric(horizontal: AuroraSpacing.space6),
        decoration: BoxDecoration(
          borderRadius: AuroraRadius.md,
          border: Border.all(
            color: AuroraColors.inkBorder,
            width: AuroraBorders.regular,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              size: a.of(AuroraDocsA.searchGlyph),
              color: AuroraColors.inkPlaceholder,
            ),
            SizedBox(width: a.of(AuroraSpacing.space4)),
            Expanded(
              child: Text(
                DocsCopy.searchHint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AuroraDocsAType.searchHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
