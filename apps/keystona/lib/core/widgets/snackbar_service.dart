import 'package:flutter/material.dart';

import '../theme/aurora_colors.dart';
import '../theme/aurora_typography.dart';

/// Static helper for showing consistent snackbars across the app.
///
/// Always use this class instead of calling [ScaffoldMessenger] directly.
/// Error snackbars display for 3 seconds; success and warning for 2 seconds.
abstract final class SnackbarService {
  /// Shows a red error snackbar with the given [message].
  ///
  /// Duration: 3 seconds.
  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: const Color(0xFFD32F2F),
      duration: const Duration(seconds: 3),
    );
  }

  /// Shows a green success snackbar with the given [message].
  ///
  /// Duration: 2 seconds.
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: AuroraColors.limeDeep,
      duration: const Duration(seconds: 2),
    );
  }

  /// Shows an orange warning snackbar with the given [message].
  ///
  /// Duration: 2 seconds.
  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: AuroraColors.yellow,
      duration: const Duration(seconds: 2),
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required Duration duration,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AuroraType.body.copyWith(color: Colors.white),
          ),
          backgroundColor: backgroundColor,
          duration: duration,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
