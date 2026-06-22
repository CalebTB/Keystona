import 'package:flutter/material.dart';

import '../../theme/aurora_colors.dart';
import '../../theme/aurora_radius.dart';
import '../../theme/aurora_spacing.dart';
import '../../theme/aurora_typography.dart';

/// Tappable select field — same visual container as AuroraTextField.
///
/// This widget only handles the display. The caller is responsible for opening
/// a picker (CupertinoActionSheet, BottomSheet, etc.) inside [onTap].
class AuroraSelectField extends StatelessWidget {
  const AuroraSelectField({
    super.key,
    required this.label,
    required this.onTap,
    this.required = false,
    this.value,
    this.placeholder = 'Select',
    this.suffix,
  });

  final String label;
  final bool required;

  /// Currently selected display value. Null shows [placeholder].
  final String? value;

  final String placeholder;

  /// Defaults to a chevron_right icon in inkTertiary.
  final Widget? suffix;

  /// Opens a picker sheet. Caller implements picker logic.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _FieldLabel(label: label, isRequired: required),
        const SizedBox(height: AuroraSpacing.space1),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(
              horizontal: AuroraSpacing.space7,
            ),
            decoration: BoxDecoration(
              color: AuroraColors.paper,
              borderRadius: AuroraRadius.md,
              border: Border.all(
                color: AuroraColors.inkBorder,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? value! : placeholder,
                    style: AuroraType.body.copyWith(
                      color: hasValue
                          ? AuroraColors.ink
                          : AuroraColors.inkTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AuroraSpacing.space3),
                suffix ??
                    const Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: AuroraColors.inkTertiary,
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.isRequired});

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    if (!isRequired) {
      return Text(
        label.toUpperCase(),
        style: AuroraType.label.copyWith(color: AuroraColors.inkSecondary),
      );
    }
    return RichText(
      text: TextSpan(
        text: label.toUpperCase(),
        style: AuroraType.label.copyWith(color: AuroraColors.inkSecondary),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(color: AuroraColors.coral),
          ),
        ],
      ),
    );
  }
}
