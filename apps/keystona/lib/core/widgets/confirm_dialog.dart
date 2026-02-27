import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text_styles.dart';

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

  /// When true the confirm button uses [AppColors.error]. Defaults to true.
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
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
        AppSizes.md,
        AppSizes.lg,
        AppSizes.md,
        AppSizes.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTextStyles.h3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.lg),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              onConfirm();
            },
            style: FilledButton.styleFrom(
              backgroundColor: isDestructive ? AppColors.error : AppColors.deepNavy,
              minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
            ),
            child: Text(
              confirmLabel,
              style: AppTextStyles.button.copyWith(
                color: AppColors.textInverse,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelLabel,
              style: AppTextStyles.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
