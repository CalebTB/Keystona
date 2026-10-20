import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_c.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// The search field with the chosen category as a token inside it, and the
/// coral Cancel beside it.
class SearchFieldBar extends StatelessWidget {
  const SearchFieldBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClearText,
    required this.onClearToken,
    required this.onCancel,
    this.tokenLabel,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClearText;
  final VoidCallback onClearToken;
  final VoidCallback onCancel;

  /// Name of the category searched in, or null for everything.
  final String? tokenLabel;

  /// Share of the row between the category token and the text, so a long
  /// name never squeezes the text to nothing (or the reverse).
  static const int _tokenFlex = 3;
  static const int _fieldFlex = 2;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Row(
      children: [
        Expanded(
          child: Container(
            constraints: BoxConstraints(
              minHeight: a.minControl(AuroraDocsCSizes.searchFieldHeight),
            ),
            padding: EdgeInsets.only(
              left: a.of(AuroraSpacing.space5),
              right: a.of(AuroraSpacing.space4),
            ),
            decoration: BoxDecoration(
              borderRadius: AuroraRadius.md,
              border: Border.all(
                color: AuroraColors.ink,
                width: AuroraBorders.emphasis,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  size: a.of(AuroraIconSizes.md),
                  color: AuroraColors.inkSecondary,
                ),
                SizedBox(width: a.of(AuroraSpacing.space3)),
                if (tokenLabel != null) ...[
                  Flexible(
                    flex: _tokenFlex,
                    child: _Token(label: tokenLabel!, onRemove: onClearToken),
                  ),
                  SizedBox(width: a.of(AuroraSpacing.space3)),
                ],
                Expanded(
                  flex: _fieldFlex,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    style: AuroraDocsCType.searchInput,
                    cursorColor: AuroraColors.cobalt,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: tokenLabel == null
                          ? 'Search name or category'
                          : 'Search ${tokenLabel!.toLowerCase()}',
                      hintStyle: AuroraDocsCType.searchInput.copyWith(
                        color: AuroraColors.inkPlaceholder,
                      ),
                    ),
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (_, value, _) => value.text.isEmpty
                      ? const SizedBox.shrink()
                      : AuroraPressable(
                          onTap: onClearText,
                          semanticLabel: 'Clear search',
                          enforceTouchTarget: true,
                          child: Icon(
                            Icons.cancel,
                            size: a.of(AuroraIconSizes.md),
                            color: AuroraColors.inkPlaceholder,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: a.of(AuroraSpacing.space5)),
        AuroraPressable(
          onTap: onCancel,
          semanticLabel: 'Cancel',
          enforceTouchTarget: true,
          child: Text(
            'Cancel',
            style: AuroraType.button.copyWith(color: AuroraColors.coral),
          ),
        ),
      ],
    );
  }
}

class _Token extends StatelessWidget {
  const _Token({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onRemove,
      semanticLabel: 'Remove $label',
      enforceTouchTarget: true,
      child: Container(
        constraints: BoxConstraints(
          minHeight: a.of(AuroraDocsCSizes.searchTokenHeight),
        ),
        padding: EdgeInsets.only(
          left: a.of(AuroraSpacing.space4),
          right: a.of(AuroraSpacing.space2),
        ),
        decoration: const BoxDecoration(
          color: AuroraColors.ink,
          borderRadius: AuroraRadius.full,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                style: AuroraType.chip.copyWith(color: AuroraColors.paper),
              ),
              SizedBox(width: a.of(AuroraSpacing.space1)),
              Icon(
                Icons.close,
                size: a.of(AuroraIconSizes.sm),
                color: AuroraOnInk.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
