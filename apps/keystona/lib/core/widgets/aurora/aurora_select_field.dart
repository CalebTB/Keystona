import 'package:flutter/material.dart';

import '../../theme/aurora_colors.dart';
import '../../theme/aurora_scale.dart';
import '../../theme/aurora_sizes.dart';
import '../../theme/aurora_spacing.dart';
import '../../theme/aurora_typography.dart';
import 'aurora_field_chrome.dart';
import 'aurora_pressable.dart';

/// Tappable select field — same box as [AuroraTextField] (50 pt, 12 radius,
/// 1 pt ink 18% border), with a chevron-down.
///
/// This widget only handles the display. The caller is responsible for opening
/// a picker (action sheet, bottom sheet, etc.) inside [onTap].
class AuroraSelectField extends StatelessWidget {
  const AuroraSelectField({
    super.key,
    required this.label,
    required this.onTap,
    this.required = false,
    this.value,
    this.placeholder = 'Select',
    this.suffix,
    this.helperText,
    this.expanded = false,
  });

  final String label;
  final bool required;

  /// Currently selected display value. Null shows [placeholder].
  final String? value;

  final String placeholder;

  /// Defaults to a chevron-down in ink 45%.
  final Widget? suffix;

  /// Rendered uppercase below the field.
  final String? helperText;

  /// True while the picker this field opens is showing: cobalt 1.5 pt border.
  final bool expanded;

  /// Opens a picker sheet. Caller implements picker logic.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final hasValue = value != null && value!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AuroraFieldLabel(label: label, isRequired: required),
        SizedBox(height: a.of(AuroraSpacing.space2)),
        AuroraPressable(
          onTap: onTap,
          semanticLabel: hasValue ? '$label, $value' : label,
          child: AuroraFieldBox(
            active: expanded,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? value! : placeholder,
                    style: AuroraType.input.copyWith(
                      color: hasValue
                          ? AuroraColors.ink
                          : AuroraColors.inkPlaceholder,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: a.of(AuroraSpacing.space3)),
                suffix ??
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: a.of(AuroraIconSizes.sm),
                      color: AuroraColors.inkHelper,
                    ),
              ],
            ),
          ),
        ),
        if (helperText != null) ...[
          SizedBox(height: a.of(AuroraSpacing.space2)),
          AuroraFieldHelper(text: helperText!),
        ],
      ],
    );
  }
}
