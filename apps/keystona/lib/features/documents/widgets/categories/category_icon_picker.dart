import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_a.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../categories_copy.dart';
import '../../models/category_icons.dart';

/// The icon choices for a category: a wrapping row of squares, the selected
/// one filled ink.
class CategoryIconPicker extends StatelessWidget {
  const CategoryIconPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Semantics(
      container: true,
      label: CategoriesCopy.iconLabel,
      child: Wrap(
        spacing: a.of(AuroraSpacing.space2),
        runSpacing: a.of(AuroraSpacing.space2),
        children: [
          for (final key in CategoryIcons.picker)
            _IconOption(
              iconKey: key,
              selected: key == selected,
              onTap: () => onSelected(key),
            ),
        ],
      ),
    );
  }
}

class _IconOption extends StatelessWidget {
  const _IconOption({
    required this.iconKey,
    required this.selected,
    required this.onTap,
  });

  final String iconKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: '${CategoriesCopy.iconLabel} $iconKey',
      child: Container(
        width: AuroraDocsA.iconPick,
        height: AuroraDocsA.iconPick,
        decoration: BoxDecoration(
          color: selected ? AuroraColors.ink : null,
          borderRadius: AuroraRadius.md,
          border: selected
              ? null
              : Border.all(
                  color: AuroraColors.inkInputBorder,
                  width: AuroraBorders.regular,
                ),
        ),
        child: Icon(
          CategoryIcons.forKey(iconKey),
          size: a.of(AuroraIconSizes.lg),
          color: selected ? AuroraColors.paper : AuroraColors.ink,
        ),
      ),
    );
  }
}
