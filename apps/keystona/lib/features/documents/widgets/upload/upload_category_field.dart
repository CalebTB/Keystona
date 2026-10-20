import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import 'upload_box_field.dart';

/// Category select: shows the choice and opens the picker sheet.
class UploadCategoryField extends StatelessWidget {
  const UploadCategoryField({
    super.key,
    required this.name,
    required this.edged,
    required this.onTap,
  });

  final String name;
  final bool edged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final hasValue = name.isNotEmpty;
    return UploadBoxField(
      label: 'Category',
      isRequired: true,
      edged: edged,
      onTap: onTap,
      semanticLabel: hasValue ? 'Category, $name' : 'Category',
      child: Row(
        children: [
          Expanded(
            child: Text(
              hasValue ? name : 'Select',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AuroraType.input.copyWith(
                color: hasValue
                    ? AuroraColors.ink
                    : AuroraColors.inkPlaceholder,
              ),
            ),
          ),
          SizedBox(width: a.of(AuroraSpacing.space3)),
          Icon(
            Icons.keyboard_arrow_down,
            size: a.of(AuroraIconSizes.sm),
            color: AuroraColors.inkHelper,
          ),
        ],
      ),
    );
  }
}
