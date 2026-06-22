import 'package:flutter/material.dart';

import '../theme/aurora_colors.dart';
import '../theme/aurora_radius.dart';
import '../theme/aurora_spacing.dart';
import '../theme/aurora_typography.dart';

/// Bottom sheet confirmation dialog for destructive or irreversible actions.
///
/// Always use the static [ConfirmDialog.show] helper to present this sheet.
/// Returns `true` when the user confirms, `false` when cancelled, and
/// `null` when the sheet is dismissed by tapping outside.
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

  /// Bold heading at the top of the sheet.
  final String title;

  /// Descriptive body text explaining what will happen.
  final String message;

  /// Label on the confirm button (e.g. "Delete", "Remove", "Archive").
  final String confirmLabel;

  /// Callback invoked when the user taps the confirm button.
  final VoidCallback onConfirm;

  /// Label on the dismiss button. Defaults to "Cancel".
  final String cancelLabel;

  /// When true the confirm button uses [AuroraColors.coral]. Defaults to true.
  final bool isDestructive;

  /// Presents the confirmation sheet and returns the user's choice.
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
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AuroraRadius.xl),
      ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AuroraSpacing.screenPadH,
        AuroraSpacing.space7,
        AuroraSpacing.screenPadH,
        AuroraSpacing.space10,
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
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              onConfirm();
            },
            style: FilledButton.styleFrom(
              backgroundColor:
                  isDestructive ? AuroraColors.coral : AuroraColors.cobalt,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: AuroraRadius.md),
            ),
            child: Text(
              confirmLabel,
              style: AuroraType.body.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: AuroraSpacing.space3),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelLabel,
              style: AuroraType.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AuroraColors.inkSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
