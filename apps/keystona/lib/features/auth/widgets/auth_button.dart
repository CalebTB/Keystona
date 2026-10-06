import 'package:flutter/material.dart';

import '../../../core/theme/aurora_auth.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_motion.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_sizes.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/widgets/aurora/aurora_pressable.dart';

/// Look of an [AuthButton].
enum AuthButtonStyle {
  /// Coral fill, paper label — the screen's one primary action.
  primary,

  /// Paper fill, ink 20% outline, ink label.
  secondary,

  /// Sign in with Apple: black fill, paper label.
  apple,

  /// Sign in with Google: paper fill, hairline outline, near-black label.
  google,
}

/// The 14-radius, 52 pt button the sign-in screens draw (kit PNGs).
///
/// Height is a minimum so large text grows the button. A null [onPressed]
/// looks disabled for [AuthButtonStyle.primary] and dims the others.
class AuthButton extends StatelessWidget {
  const AuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = AuthButtonStyle.primary,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AuthButtonStyle style;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final enabled = onPressed != null && !loading;
    final disabledLook = onPressed == null && !loading;

    final Color fill;
    final Color foreground;
    final Color? border;
    switch (style) {
      case AuthButtonStyle.primary:
        fill = disabledLook ? AuroraColors.inkDisabledFill : AuroraColors.coral;
        foreground = disabledLook
            ? AuroraColors.inkPlaceholder
            : AuroraColors.paper;
        border = null;
      case AuthButtonStyle.secondary:
        fill = AuroraColors.paper;
        foreground = AuroraColors.ink;
        border = AuroraColors.inkBorderStrong;
      case AuthButtonStyle.apple:
        fill = AuroraAuthColors.appleFill;
        foreground = AuroraColors.paper;
        border = null;
      case AuthButtonStyle.google:
        fill = AuroraColors.paper;
        foreground = AuroraAuthColors.googleLabel;
        border = AuroraColors.inkBorderStrong;
    }
    final dim = disabledLook && style != AuthButtonStyle.primary;

    final Widget content = loading
        ? SizedBox.square(
            dimension: a.of(AuroraSizes.spinner),
            child: CircularProgressIndicator(
              strokeWidth: AuroraBorders.spinnerStroke,
              valueColor: AlwaysStoppedAnimation<Color>(foreground),
            ),
          )
        : Text(
            label,
            textAlign: TextAlign.center,
            style: AuroraAuthType.button.copyWith(color: foreground),
          );

    return AuroraPressable(
      onTap: enabled ? onPressed : null,
      semanticLabel: label,
      child: Opacity(
        opacity: dim ? AuroraOpacity.disabled : 1,
        child: Container(
          constraints: BoxConstraints(
            minHeight: a.minControl(AuroraAuthSizes.buttonHeight),
          ),
          padding: a.symmetric(horizontal: AuroraSpacing.pillH),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: AuroraRadius.lg,
            border: border == null
                ? null
                : Border.all(
                    color: border,
                    width: style == AuthButtonStyle.secondary
                        ? AuroraBorders.emphasis
                        : AuroraBorders.regular,
                  ),
          ),
          child: Center(widthFactor: 1, heightFactor: 1, child: content),
        ),
      ),
    );
  }
}
