import 'package:flutter/material.dart';

import '../theme/aurora_colors.dart';
import '../theme/aurora_spacing.dart';
import '../theme/aurora_typography.dart';
import 'aurora/aurora_button.dart';

/// Full-screen error state displayed when an async operation fails.
///
/// Always includes a retry mechanism so users are never left stuck.
/// Use this as the `error` branch of every `AsyncValue.when()` call.
///
/// Aurora spec: 48px inkTertiary icon, body inkSecondary text,
/// GhostButton retry (coral text).
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
        padding: const EdgeInsets.all(AuroraSpacing.space9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AuroraColors.inkTertiary,
            ),
            const SizedBox(height: AuroraSpacing.space7),
            Text(
              message,
              style: AuroraType.body.copyWith(
                color: AuroraColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AuroraSpacing.space7),
              GhostButton(
                label: retryLabel,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
