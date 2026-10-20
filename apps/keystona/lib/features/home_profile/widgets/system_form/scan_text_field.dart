import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/widgets/aurora/aurora_field_chrome.dart';
import '../shared/scan_field_box.dart';

/// A text field whose box carries the cobalt "from scan" edge while
/// [fromScan] is true. Same look as `AuroraTextField`, with the edge on the
/// box only (not on its label).
class ScanTextField extends StatefulWidget {
  const ScanTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.fromScan,
    this.hintText,
    this.helperText,
    this.suffix,
    this.maxLength,
  });

  final String label;
  final TextEditingController controller;
  final bool fromScan;
  final String? hintText;
  final String? helperText;
  final Widget? suffix;
  final int? maxLength;

  @override
  State<ScanTextField> createState() => _ScanTextFieldState();
}

class _ScanTextFieldState extends State<ScanTextField> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AuroraFieldLabel(label: widget.label, isRequired: false),
        SizedBox(height: a.of(AuroraSpacing.space2)),
        ScanFieldBox(
          fromScan: widget.fromScan,
          child: AuroraFieldBox(
            active: _focused,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    maxLength: widget.maxLength,
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
                ),
                if (widget.suffix != null) ...[
                  SizedBox(width: a.of(AuroraSpacing.space3)),
                  widget.suffix!,
                ],
              ],
            ),
          ),
        ),
        if (widget.helperText != null) ...[
          SizedBox(height: a.of(AuroraSpacing.space2)),
          AuroraFieldHelper(text: widget.helperText!),
        ],
      ],
    );
  }
}
