import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_b.dart';
import '../../../../core/theme/aurora_radius.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_field_chrome.dart';
import '../../../../core/widgets/aurora/aurora_pressable.dart';

/// Tags: chips with an x, and an input that adds on return or comma.
class UploadTagsField extends StatefulWidget {
  const UploadTagsField({
    super.key,
    required this.tags,
    required this.onAdd,
    required this.onRemove,
    required this.enabled,
  });

  final List<String> tags;

  /// Returns false when the tag was refused (blank, repeat, too long, full).
  final bool Function(String tag) onAdd;
  final ValueChanged<String> onRemove;
  final bool enabled;

  @override
  State<UploadTagsField> createState() => _UploadTagsFieldState();
}

class _UploadTagsFieldState extends State<UploadTagsField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit(String raw) {
    if (widget.onAdd(raw)) _controller.clear();
  }

  void _onChanged(String value) {
    if (!value.contains(',')) return;
    // Everything before the comma is a tag; keep typing after it.
    final parts = value.split(',');
    _commit(parts.first);
    _controller.value = TextEditingValue(
      text: parts.skip(1).join(' ').trimLeft(),
      selection: TextSelection.collapsed(
        offset: parts.skip(1).join(' ').trimLeft().length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const AuroraFieldLabel(label: 'Tags', isRequired: false),
        SizedBox(height: a.of(AuroraSpacing.space2)),
        Container(
          constraints: BoxConstraints(
            minHeight: a.minControl(AuroraSizes.inputHeight),
          ),
          padding: a.symmetric(
            horizontal: AuroraSpacing.space4,
            vertical: AuroraSpacing.space2,
          ),
          decoration: BoxDecoration(
            borderRadius: AuroraRadius.md,
            border: Border.all(
              color: AuroraColors.inkInputBorder,
              width: AuroraBorders.regular,
            ),
          ),
          child: Wrap(
            spacing: a.of(AuroraSpacing.space2),
            runSpacing: a.of(AuroraSpacing.space2),
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final tag in widget.tags)
                _TagChip(
                  tag: tag,
                  onRemove: widget.enabled ? () => widget.onRemove(tag) : null,
                ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: a.of(AuroraUploadSizes.tagInputMinWidth),
                  maxWidth: a.contentMaxWidth,
                ),
                child: IntrinsicWidth(
                  child: TextField(
                    controller: _controller,
                    enabled: widget.enabled,
                    onChanged: _onChanged,
                    onSubmitted: _commit,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(
                        AuroraUploadRules.maxTagLength + 1,
                      ),
                    ],
                    style: AuroraType.input,
                    cursorColor: AuroraColors.cobalt,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      hintText: 'Add a tag',
                      hintStyle: AuroraType.input.copyWith(
                        color: AuroraColors.inkPlaceholder,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: a.of(AuroraSpacing.space2)),
        const AuroraFieldHelper(text: 'Press return or comma to add · up to 8'),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag, required this.onRemove});

  final String tag;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      constraints: BoxConstraints(minHeight: a.of(AuroraUploadSizes.tagHeight)),
      padding: EdgeInsetsDirectional.only(start: a.of(AuroraSpacing.space4)),
      decoration: BoxDecoration(
        borderRadius: AuroraRadius.full,
        border: Border.all(
          color: AuroraColors.inkInputBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              tag,
              overflow: TextOverflow.ellipsis,
              style: AuroraType.chip,
            ),
          ),
          AuroraPressable(
            onTap: onRemove,
            semanticLabel: 'Remove tag $tag',
            enforceTouchTarget: true,
            child: Icon(
              Icons.close,
              size: a.of(AuroraIconSizes.xs),
              color: AuroraColors.inkHelper,
            ),
          ),
        ],
      ),
    );
  }
}
