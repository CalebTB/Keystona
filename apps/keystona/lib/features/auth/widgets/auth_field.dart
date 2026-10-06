import 'package:flutter/material.dart';

import '../../../core/theme/aurora_auth.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/aurora/aurora_pressable.dart';
import '../../../core/widgets/aurora/aurora_field_chrome.dart';
import '../auth_copy.dart';

/// Text field for the sign-in screens, built from the Aurora field chrome.
///
/// Adds what `AuroraTextField` does not have: a hidden-text mode with a
/// Show / Hide toggle, autofill hints and keyboard actions. The error shows
/// only after the user has left the field once, and only when [errorFor]
/// returns text for the current value.
class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.errorFor,
    this.password = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;

  /// Returns the message to show for [value], or null when it is fine.
  final String? Function(String value)? errorFor;

  /// Hides the text and adds the Show / Hide toggle.
  final bool password;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  final FocusNode _focus = FocusNode();
  bool _touched = false;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() {
    if (!mounted) return;
    setState(() {
      if (!_focus.hasFocus) _touched = true;
    });
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, _) {
        final error = _touched ? widget.errorFor?.call(value.text) : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AuroraFieldLabel(label: widget.label, isRequired: false),
            SizedBox(height: a.of(AuroraSpacing.space2)),
            AuroraFieldBox(
              active: _focus.hasFocus,
              error: error != null,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      enabled: widget.enabled,
                      obscureText: widget.password && !_revealed,
                      autocorrect: false,
                      enableSuggestions: !widget.password,
                      keyboardType: widget.keyboardType,
                      textInputAction: widget.textInputAction,
                      textCapitalization: widget.textCapitalization,
                      autofillHints: widget.autofillHints,
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
                        disabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText: widget.hintText,
                        hintStyle: AuroraType.input.copyWith(
                          color: AuroraColors.inkPlaceholder,
                        ),
                      ),
                    ),
                  ),
                  if (widget.password) ...[
                    SizedBox(width: a.of(AuroraSpacing.space3)),
                    AuroraPressable(
                      onTap: () => setState(() => _revealed = !_revealed),
                      semanticLabel: _revealed
                          ? AuthCopy.hidePassword
                          : AuthCopy.showPassword,
                      enforceTouchTarget: true,
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          _revealed ? AuthCopy.hide : AuthCopy.show,
                          style: AuroraAuthType.reveal,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (error != null) ...[
              SizedBox(height: a.of(AuroraSpacing.space2)),
              Text(error, style: AuroraAuthType.fieldError),
            ],
          ],
        );
      },
    );
  }
}
