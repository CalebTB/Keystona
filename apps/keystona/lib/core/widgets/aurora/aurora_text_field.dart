import 'package:flutter/material.dart';

import '../../theme/aurora_colors.dart';
import '../../theme/aurora_radius.dart';
import '../../theme/aurora_spacing.dart';
import '../../theme/aurora_typography.dart';

/// Single-line or multi-line text field following Aurora Design System v2.0.
///
/// Pass [maxLines] > 1 for a textarea (no fixed height).
/// Single-line fields have a 48px total height.
/// Focus state: coral 2px border + focusCoral glow shadow.
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

  /// Rendered uppercase below the field in labelSm / inkTertiary.
  final String? helperText;

  final TextInputType? keyboardType;
  final int? maxLength;

  /// 1 = single-line 48px height. > 1 = textarea with 120px min-height.
  final int maxLines;

  final bool readOnly;
  final VoidCallback? onTap;

  /// Inline widget rendered on the right inside the input (e.g. scan icon).
  final Widget? suffix;

  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;

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
    if (widget.focusNode == null) {
      _focusNode.removeListener(_onFocusChange);
      _focusNode.dispose();
    }
    super.dispose();
  }

  BoxDecoration get _containerDecoration => BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: AuroraRadius.md,
        border: Border.all(
          color: _isFocused ? AuroraColors.coral : AuroraColors.inkBorder,
          width: _isFocused ? 2.0 : 1.5,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AuroraColors.focusCoral,
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ]
            : null,
      );

  bool get _isTextarea => widget.maxLines > 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _FieldLabel(label: widget.label, isRequired: widget.required),
        const SizedBox(height: AuroraSpacing.space1),
        Container(
          constraints: _isTextarea
              ? const BoxConstraints(minHeight: 120)
              : const BoxConstraints(minHeight: 48),
          decoration: _containerDecoration,
          padding: const EdgeInsets.symmetric(
            horizontal: AuroraSpacing.space7,
            vertical: AuroraSpacing.space5,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            maxLength: widget.maxLength,
            maxLines: widget.maxLines,
            minLines: _isTextarea ? 4 : 1,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            onChanged: widget.onChanged,
            validator: widget.validator,
            style: AuroraType.body,
            cursorColor: AuroraColors.coral,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: widget.hintText,
              hintStyle: AuroraType.body.copyWith(
                color: AuroraColors.inkTertiary,
              ),
              suffixIcon: widget.suffix,
              counterText: '',
            ),
          ),
        ),
        if (widget.helperText != null) ...[
          const SizedBox(height: AuroraSpacing.space1),
          Text(
            widget.helperText!.toUpperCase(),
            style: AuroraType.labelSm.copyWith(color: AuroraColors.inkTertiary),
          ),
        ],
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
