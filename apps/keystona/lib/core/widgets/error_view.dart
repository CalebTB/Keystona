import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text_styles.dart';

/// Full-screen error state displayed when an async operation fails.
///
/// Always includes a retry mechanism so users are never left stuck.
/// Use this as the `error` branch of every `AsyncValue.when()` call.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try Again',
  });

  /// User-friendly error message. Never pass raw exception strings here.
  final String message;

  /// Callback invoked when the user taps the retry button.
  /// When null the retry button is not shown.
  final VoidCallback? onRetry;

  /// Label for the retry button. Defaults to "Try Again".
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: AppSizes.iconXl,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSizes.lg),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.deepNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                ),
                child: Text(
                  retryLabel,
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
