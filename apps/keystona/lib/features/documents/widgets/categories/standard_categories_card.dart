import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_a.dart';
import '../../../../core/theme/aurora_motion.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../categories_copy.dart';

/// "10 standard categories": a collapsed disclosure naming the built-in
/// categories, which can't be renamed or removed.
class StandardCategoriesCard extends StatefulWidget {
  const StandardCategoriesCard({super.key, required this.names});

  final List<String> names;

  @override
  State<StandardCategoriesCard> createState() => _StandardCategoriesCardState();
}

class _StandardCategoriesCardState extends State<StandardCategoriesCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final title = CategoriesCopy.standardTitle(widget.names.length);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.xl,
        border: Border.all(
          color: AuroraColors.inkBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Padding(
        padding: a.symmetric(horizontal: AuroraSpacing.space6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuroraPressable(
              onTap: () => setState(() => _open = !_open),
              semanticLabel: title,
              selected: _open,
              child: Container(
                constraints: BoxConstraints(
                  minHeight: a.minControl(AuroraDocsA.disclosureMinHeight),
                ),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Expanded(child: Text(title, style: AuroraType.button)),
                    Icon(
                      _open ? Icons.expand_less : Icons.expand_more,
                      size: a.of(AuroraIconSizes.xl),
                      color: AuroraColors.inkSubtle,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: AuroraDurations.fast,
              alignment: Alignment.topCenter,
              child: _open
                  ? Padding(
                      padding: EdgeInsets.only(
                        bottom: a.of(AuroraSpacing.space6),
                      ),
                      child: Text(
                        CategoriesCopy.standardBody(widget.names),
                        style: AuroraDocsAType.confirmBody,
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}
