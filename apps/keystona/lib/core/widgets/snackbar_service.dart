import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/aurora_colors.dart';
import '../theme/aurora_motion.dart';
import '../theme/aurora_radius.dart';
import '../theme/aurora_scale.dart';
import '../theme/aurora_shadows.dart';
import '../theme/aurora_sizes.dart';
import '../theme/aurora_spacing.dart';
import '../theme/aurora_typography.dart';

/// Static helper for showing the Aurora snackbar (kit: dark ink toast).
///
/// Kit spec: ink background, 16 radius, snackbar shadow, bold message with an
/// optional second line, floating above the tab bar. Undo toasts carry a lime
/// "Undo" action with a 44 pt target and stay for [AuroraDurations.undo].
/// Status toasts keep a small status-colored icon and always say it in words.
///
/// Always use this class instead of calling [ScaffoldMessenger] directly.
abstract final class SnackbarService {
  /// Shows a success toast with a lime check icon.
  static void showSuccess(
    BuildContext context,
    String message, {
    String? subtitle,
  }) {
    _show(
      context,
      message: message,
      subtitle: subtitle,
      icon: CupertinoIcons.checkmark_alt_circle,
      iconColor: AuroraColors.lime,
      duration: AuroraSnackbarDurations.success,
    );
  }

  /// Shows an info toast.
  static void showInfo(
    BuildContext context,
    String message, {
    String? subtitle,
  }) {
    _show(
      context,
      message: message,
      subtitle: subtitle,
      icon: CupertinoIcons.info_circle,
      iconColor: AuroraColors.paper,
      duration: AuroraSnackbarDurations.info,
    );
  }

  /// Shows a warning toast with an amber icon.
  static void showWarning(
    BuildContext context,
    String message, {
    String? subtitle,
  }) {
    _show(
      context,
      message: message,
      subtitle: subtitle,
      icon: CupertinoIcons.exclamationmark_triangle,
      iconColor: AuroraColors.yellow,
      duration: AuroraSnackbarDurations.warning,
    );
  }

  /// Shows an error toast with a coral icon. Stays longest.
  static void showError(
    BuildContext context,
    String message, {
    String? subtitle,
  }) {
    _show(
      context,
      message: message,
      subtitle: subtitle,
      icon: CupertinoIcons.xmark_circle,
      iconColor: AuroraColors.coral,
      duration: AuroraSnackbarDurations.error,
    );
  }

  /// Shows an action toast with a lime Undo button.
  ///
  /// Every task and destructive action ends with one of these. [onUndo] runs
  /// when the button is tapped; the toast then dismisses.
  static void showUndo(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    String? subtitle,
    String actionLabel = 'Undo',
    Duration duration = AuroraDurations.undo,
  }) {
    _show(
      context,
      message: message,
      subtitle: subtitle,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onUndo,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Duration duration,
    String? subtitle,
    IconData? icon,
    Color? iconColor,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final a = context.aurora;
    final messenger = ScaffoldMessenger.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final side = math.max(
      a.of(AuroraSpacing.space5),
      (width - a.contentMaxWidth) / 2,
    );
    final bottom = a.of(AuroraSizes.tabBarHeight + AuroraSpacing.space8);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: _SnackbarBody(
            message: message,
            subtitle: subtitle,
            icon: icon,
            iconColor: iconColor,
            actionLabel: actionLabel,
            onAction: onAction == null
                ? null
                : () {
                    messenger.hideCurrentSnackBar();
                    onAction();
                  },
          ),
          backgroundColor: AuroraStructure.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          clipBehavior: Clip.none,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(side, 0, side, bottom),
          shape: const RoundedRectangleBorder(borderRadius: AuroraRadius.xl),
        ),
      );
  }
}

class _SnackbarBody extends StatelessWidget {
  const _SnackbarBody({
    required this.message,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      padding: EdgeInsets.fromLTRB(
        a.of(AuroraSpacing.space7),
        a.of(AuroraSpacing.space5),
        a.of(onAction == null ? AuroraSpacing.space7 : AuroraSpacing.space3),
        a.of(AuroraSpacing.space5),
      ),
      decoration: const BoxDecoration(
        color: AuroraColors.ink,
        borderRadius: AuroraRadius.xl,
        boxShadow: AuroraShadows.snackbar,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: a.of(AuroraIconSizes.md), color: iconColor),
            SizedBox(width: a.of(AuroraSpacing.space4)),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: AuroraSharedType.snackbarTitle),
                if (subtitle != null) ...[
                  SizedBox(height: a.of(AuroraSpacing.space1)),
                  Text(subtitle!, style: AuroraSharedType.snackbarSub),
                ],
              ],
            ),
          ),
          if (onAction != null) ...[
            SizedBox(width: a.of(AuroraSpacing.space5)),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AuroraColors.lime,
                minimumSize: Size(
                  a.of(AuroraSharedSizes.snackbarActionMinWidth),
                  AuroraSizes.minTouch,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: a.of(AuroraSpacing.space5),
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: AuroraRadius.md,
                ),
                splashFactory: NoSplash.splashFactory,
                textStyle: AuroraSharedType.snackbarAction,
              ),
              child: Text(actionLabel ?? ''),
            ),
          ],
        ],
      ),
    );
  }
}
