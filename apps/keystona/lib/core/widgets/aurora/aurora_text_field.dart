import 'package:flutter/material.dart';

import '../../theme/aurora_colors.dart';
import '../../theme/aurora_scale.dart';
import '../../theme/aurora_spacing.dart';
import '../../theme/aurora_typography.dart';
import 'aurora_field_chrome.dart';

/// Single-line or multi-line text field following the Aurora kit.
///
/// 50 pt minimum height, 12 radius, 1 pt ink 18% border, uppercase 10 pt label
/// above and uppercase helper text below. Focus turns the border cobalt
/// (1.5 pt). A failing [validator] turns it coral and shows the message below.
///
/// Pass [maxLines] > 1 for a textarea (opens at up to 3 lines and grows).
class AuroraTextField extends StatefulWidget {
  const AuroraTextField({
    super.key,
    required this.label,
    required this.controller,
    this.required = false,
    this.hintText,
    this.helperText,
    this.keyboardType,
    this.maxLength,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.suffix,
    this.validator,
    this.onChanged,
    this.focusNode,
  });

  final String label;
  final TextEditingController controller;
  final bool required;
  final String? hintText;

  /// Rendered uppercase below the field.
  final String? helperText;

  final TextInputType? keyboardType;
  final int? maxLength;

  /// 1 = single line. > 1 = textarea.
  final int maxLines;

  final bool readOnly;
  final VoidCallback? onTap;

  /// Inline widget rendered on the right inside the input (e.g. scan icon).
  final Widget? suffix;

  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;

  /// A textarea opens at this many lines (never more than [maxLines]).
  static const int textareaOpenLines = 3;

  @override
  State<AuroraTextField> createState() => _AuroraTextFieldState();
}

class _AuroraTextFieldState extends State<AuroraTextField> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  bool get _isTextarea => widget.maxLines > 1;

  /// minLines must never exceed maxLines.
  int get _minLines => _isTextarea
      ? (widget.maxLines < AuroraTextField.textareaOpenLines
          ? widget.maxLines
          : AuroraTextField.textareaOpenLines)
      : 1;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return FormField<String>(
      validator: (_) => widget.validator?.call(widget.controller.text),
      builder: (state) {
        final error = state.errorText;
        final hasError = error != null;
        final helper = hasError ? error : widget.helperText;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AuroraFieldLabel(label: widget.label, isRequired: widget.required),
            SizedBox(height: a.of(AuroraSpacing.space2)),
            AuroraFieldBox(
              active: _isFocused,
              error: hasError,
              padding: a.symmetric(
                horizontal: AuroraSpacing.space6,
                vertical: _isTextarea ? AuroraSpacing.space5 : 0,
              ),
              child: Row(
                crossAxisAlignment: _isTextarea
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      keyboardType: widget.keyboardType,
                      maxLength: widget.maxLength,
                      maxLines: widget.maxLines,
                      minLines: _minLines,
                      readOnly: widget.readOnly,
                      onTap: widget.onTap,
                      onChanged: (value) {
                        state.didChange(value);
                        widget.onChanged?.call(value);
                      },
                      style: AuroraType.input,
                      cursorColor: AuroraColors.cobalt,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText: widget.hintText,
                        hintStyle: AuroraType.input.copyWith(
                          color: AuroraColors.inkPlaceholder,
                        ),
                        counterText: '',
                      ),
                    ),
                  ),
                  if (widget.suffix != null) ...[
                    SizedBox(width: a.of(AuroraSpacing.space3)),
                    widget.suffix!,
                  ],
                ],
              ),
            ),
            if (helper != null) ...[
              SizedBox(height: a.of(AuroraSpacing.space2)),
              AuroraFieldHelper(text: helper, isError: hasError),
            ],
          ],
        );
      },
    );
  }
}
