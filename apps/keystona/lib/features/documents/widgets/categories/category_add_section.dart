import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';
import '../../categories_copy.dart';
import '../../models/category_lists.dart';
import 'category_icon_picker.dart';
import 'category_name_field.dart';

/// "NEW CATEGORY": a name, an Add button and the icon choices.
class CategoryAddSection extends StatelessWidget {
  const CategoryAddSection({
    super.key,
    required this.controller,
    required this.icon,
    required this.canAdd,
    required this.onNameChanged,
    required this.onIconSelected,
    required this.onAdd,
  });

  final TextEditingController controller;
  final String icon;

  /// True when the name is not blank.
  final bool canAdd;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onIconSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(CategoriesCopy.newCategory, style: AuroraType.label),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CategoryNameField(
                controller: controller,
                hintText: CategoriesCopy.namePlaceholder,
                maxLength: CategoryLists.maxNameLength,
                onChanged: onNameChanged,
                onSubmitted: (_) => onAdd(),
              ),
            ),
            SizedBox(width: a.of(AuroraSpacing.space3)),
            _AddButton(enabled: canAdd, onTap: onAdd),
          ],
        ),
        SizedBox(height: a.of(AuroraSpacing.space3)),
        CategoryIconPicker(selected: icon, onSelected: onIconSelected),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: enabled ? onTap : null,
      semanticLabel: CategoriesCopy.add,
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.minControl(AuroraSizes.inputHeight),
        ),
        padding: a.symmetric(horizontal: AuroraSpacing.space8),
        decoration: BoxDecoration(
          color: enabled ? AuroraColors.cobalt : AuroraColors.inkDisabledFill,
          borderRadius: AuroraRadius.lg,
        ),
        alignment: Alignment.center,
        child: Text(
          CategoriesCopy.add,
          style: AuroraType.button.copyWith(
            color: enabled ? AuroraColors.paper : AuroraColors.inkPlaceholder,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
