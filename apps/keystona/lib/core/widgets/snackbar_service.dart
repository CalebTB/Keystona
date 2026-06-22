import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/aurora_colors.dart';
import '../theme/aurora_radius.dart';
import '../theme/aurora_typography.dart';

/// Static helper for showing consistent Aurora toast snackbars across the app.
///
/// Aurora toast spec:
/// - All toasts: AuroraColors.ink background (NOT colored backgrounds)
/// - Success: lime check icon, 2.5s
/// - Info: cobalt info icon, 3.5s
/// - Warning: yellow warning icon, 4.5s
/// - Error: coral error icon, persists (10s)
/// - Position: bottom, above tab bar (bottom margin 104px)
/// - Text: AuroraType.body white
///
/// Always use this class instead of calling [ScaffoldMessenger] directly.
abstract final class SnackbarService {
  /// Shows a success toast with lime check icon.
  ///
  /// Duration: 2.5 seconds.
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: CupertinoIcons.checkmark_alt_circle,
      iconColor: AuroraColors.lime,
      duration: const Duration(milliseconds: 2500),
    );
  }

  /// Shows an info toast with cobalt info icon.
  ///
  /// Duration: 3.5 seconds.
  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: CupertinoIcons.info_circle,
      iconColor: AuroraColors.cobalt,
      duration: const Duration(milliseconds: 3500),
    );
  }

  /// Shows a warning toast with yellow warning icon.
  ///
  /// Duration: 4.5 seconds.
  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: CupertinoIcons.exclamationmark_triangle,
      iconColor: AuroraColors.yellow,
      duration: const Duration(milliseconds: 4500),
    );
  }

  /// Shows an error toast with coral error icon.
  ///
  /// Duration: persists (10 seconds).
  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: CupertinoIcons.xmark_circle,
      iconColor: AuroraColors.coral,
      duration: const Duration(seconds: 10),
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color iconColor,
    required Duration duration,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: AuroraType.body.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AuroraColors.ink,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          // Position above tab bar (tab bar ~88px + 16px gap = 104px)
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 104),
          shape: const RoundedRectangleBorder(
            borderRadius: AuroraRadius.md,
          ),
        ),
      );
  }
}
