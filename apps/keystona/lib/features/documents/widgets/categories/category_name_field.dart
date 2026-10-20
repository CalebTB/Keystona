import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_field_chrome.dart';

/// A single-line text box in the Aurora field chrome, without a label above
/// it (the section heading is the label).
class CategoryNameField extends StatefulWidget {
  const CategoryNameField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.maxLength,
  });

  final TextEditingController controller;
  final String hintText;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<CategoryNameField> createState() => _CategoryNameFieldState();
}

class _CategoryNameFieldState extends State<CategoryNameField> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() {
    if (mounted) setState(() => _focused = _focus.hasFocus);
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuroraFieldBox(
      active: _focused,
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        maxLength: widget.maxLength,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        style: AuroraType.input,
        cursorColor: AuroraColors.cobalt,
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: widget.hintText,
          hintStyle: AuroraType.input.copyWith(
            color: AuroraColors.inkPlaceholder,
          ),
          counterText: '',
        ),
      ),
    );
  }
}
