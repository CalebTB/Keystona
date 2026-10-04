import 'package:flutter/material.dart';

import '../theme/aurora_colors.dart';
import '../theme/aurora_radius.dart';
import '../theme/aurora_spacing.dart';
import '../theme/aurora_typography.dart';
import 'aurora/aurora_button.dart';

/// Centered confirmation dialog for destructive or irreversible actions.
///
/// Always use the static [ConfirmDialog.show] helper to present this dialog.
/// Returns `true` when the user confirms, `false` when cancelled, and
/// `null` when the dialog is dismissed by tapping outside.
///
/// Aurora spec: paper bg, AuroraRadius.xxl, ink backdrop, max width 340px.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
    this.cancelLabel = 'Cancel',
    this.isDestructive = true,
  });

  /// Bold heading at the top of the dialog.
  final String title;

  /// Descriptive body text explaining what will happen.
  final String message;

  /// Label on the confirm button (e.g. "Delete", "Remove", "Archive").
  final String confirmLabel;

  /// Callback invoked when the user taps the confirm button.
  final VoidCallback onConfirm;

  /// Label on the dismiss button. Defaults to "Cancel".
  final String cancelLabel;

  /// When true the confirm button uses [PrimaryButton] (coral).
  /// When false uses [SaveButton] (cobalt). Defaults to true.
  final bool isDestructive;

  /// Presents the confirmation dialog and returns the user's choice.
  ///
  /// Returns `true` on confirm, `false` on cancel, `null` on outside dismiss.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required VoidCallback onConfirm,
    String cancelLabel = 'Cancel',
    bool isDestructive = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: AuroraColors.ink.withValues(alpha: 0.55),
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        onConfirm: onConfirm,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AuroraColors.paper,
      shape: const RoundedRectangleBorder(borderRadius: AuroraRadius.xxl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AuroraSpacing.screenPadH,
            AuroraSpacing.space7,
            AuroraSpacing.screenPadH,
            AuroraSpacing.space8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: AuroraType.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AuroraSpacing.space3),
              Text(
                message,
                style: AuroraType.body.copyWith(
                  color: AuroraColors.inkSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AuroraSpacing.space7),
              // Confirm action — coral for destructive, cobalt for confirmations
              if (isDestructive)
                PrimaryButton(
                  label: confirmLabel,
                  expand: true,
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    onConfirm();
                  },
                )
              else
                SaveButton(
                  label: confirmLabel,
                  expand: true,
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    onConfirm();
                  },
                ),
              const SizedBox(height: AuroraSpacing.space3),
              SecondaryButton(
                label: cancelLabel,
                expand: true,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
