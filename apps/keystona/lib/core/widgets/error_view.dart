import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/aurora_colors.dart';
import '../theme/aurora_scale.dart';
import '../theme/aurora_sizes.dart';
import '../theme/aurora_spacing.dart';
import '../theme/aurora_typography.dart';
import 'aurora/aurora_button.dart';

/// Full-screen error state displayed when an async operation fails
/// (kit: ErrorRetry).
///
/// Always includes a retry mechanism so users are never left stuck.
/// Use this as the `error` branch of every `AsyncValue.when()` call.
///
/// Kit spec: coral outlined circle with an offline-cloud glyph, 22/800 title,
/// ink 65% body, cobalt "Try again" pill, and optionally a link row that
/// reaches Emergency (it works offline).
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
    this.title,
    this.emergencyLinkLabel,
    this.onEmergency,
  });

  /// User-friendly error message. Never pass raw exception strings here.
  final String message;

  /// Callback invoked when the user taps the retry button.
  /// When null the retry button is not shown.
  final VoidCallback? onRetry;

  /// Label for the retry button. Defaults to "Try again".
  final String retryLabel;

  /// Optional bold heading above [message] ("We couldn't load your documents").
  final String? title;

  /// Label for the optional Emergency link row.
  final String? emergencyLinkLabel;

  /// Opens Emergency. The link row shows only when this and
  /// [emergencyLinkLabel] are set.
  final VoidCallback? onEmergency;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final showLink = emergencyLinkLabel != null && onEmergency != null;
    // Centered when short, scrolls (without claiming drags) when taller than
    // the space available, e.g. large text on a small phone.
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: a.contentMaxWidth),
          child: Padding(
            padding: a.all(AuroraSpacing.space9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: a.of(AuroraSharedSizes.errorIconCircle),
                  height: a.of(AuroraSharedSizes.errorIconCircle),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AuroraColors.coral,
                      width: AuroraBorders.regular,
                    ),
                  ),
                  child: Center(
                    child: ExcludeSemantics(
                      child: Icon(
                        Icons.cloud_off_outlined,
                        size: a.of(AuroraSharedSizes.errorIconGlyph),
                        color: AuroraColors.coral,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: a.of(AuroraSpacing.space6)),
                if (title != null) ...[
                  Text(
                    title!,
                    style: AuroraSharedType.stateTitle,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: a.of(AuroraSpacing.space6)),
                ],
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: a.of(AuroraSharedSizes.bodyMaxWidth),
                  ),
                  child: Text(
                    message,
                    style: AuroraSharedType.stateBody,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (onRetry != null) ...[
                  SizedBox(height: a.of(AuroraSpacing.space6)),
                  SaveButton(label: retryLabel, onPressed: onRetry),
                ],
                if (showLink) ...[
                  SizedBox(height: a.of(AuroraSpacing.space6)),
                  _EmergencyLink(
                    label: emergencyLinkLabel!,
                    onTap: onEmergency!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmergencyLink extends StatelessWidget {
  const _EmergencyLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AuroraSizes.minTouch),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: a.of(AuroraIconSizes.sm),
                color: AuroraColors.coral,
              ),
              SizedBox(width: a.of(AuroraSpacing.space3)),
              Flexible(child: Text(label, style: AuroraSharedType.linkRow)),
              SizedBox(width: a.of(AuroraSpacing.space3)),
              Icon(
                CupertinoIcons.chevron_right,
                size: a.of(AuroraIconSizes.sm),
                color: AuroraColors.inkPlaceholder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
