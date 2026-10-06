import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/aurora_colors.dart';
import '../theme/aurora_radius.dart';
import '../theme/aurora_scale.dart';
import '../theme/aurora_shadows.dart';
import '../theme/aurora_sizes.dart';
import '../theme/aurora_spacing.dart';
import '../theme/aurora_typography.dart';
import 'aurora/aurora_button.dart';

/// Centered confirmation modal for destructive or irreversible actions
/// (kit: ConfirmDelete).
///
/// Always use the static [ConfirmDialog.show] helper to present this dialog.
/// Returns `true` when the user confirms, `false` when cancelled, and
/// `null` when the dialog is dismissed by tapping outside.
///
/// Kit spec: paper card, 24 radius, scrim, modal shadow, outlined icon circle
/// (coral when destructive), 22/800 title, Cancel outline pill beside a coral
/// confirm pill.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
    this.cancelLabel = 'Cancel',
    this.isDestructive = true,
    this.icon,
    this.details,
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

  /// When true the confirm button is coral (destructive). When false it is
  /// cobalt. Defaults to true.
  final bool isDestructive;

  /// Icon in the outlined circle. Defaults to a trash can when destructive.
  final IconData? icon;

  /// Optional extra content between the message and the buttons (what else
  /// is removed, a keep/delete choice).
  final Widget? details;

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
    IconData? icon,
    Widget? details,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: AuroraColors.scrim,
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        onConfirm: onConfirm,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        icon: icon,
        details: details,
      ),
    );
  }

  /// Large text or a very narrow screen stacks the buttons.
  static const double _stackTextScale = 1.3;

  /// Kit: Cancel and confirm share the row 1 : 1.3.
  static const int _cancelFlex = 10;
  static const int _confirmFlex = 13;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final accent = isDestructive ? AuroraColors.coral : AuroraColors.cobalt;
    final glyph =
        icon ??
        (isDestructive ? CupertinoIcons.trash : CupertinoIcons.question_circle);

    void confirm() {
      Navigator.of(context).pop(true);
      onConfirm();
    }

    final confirmButton = isDestructive
        ? PrimaryButton(label: confirmLabel, expand: true, onPressed: confirm)
        : SaveButton(label: confirmLabel, expand: true, onPressed: confirm);
    final cancelButton = SecondaryButton(
      label: cancelLabel,
      expand: true,
      onPressed: () => Navigator.of(context).pop(false),
    );
    final stacked = a.textScale > _stackTextScale;

    return Dialog(
      backgroundColor: AuroraStructure.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: a.of(AuroraSpacing.space7),
        vertical: a.of(AuroraSpacing.space7),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: a.contentMaxWidth),
        child: Container(
          decoration: const BoxDecoration(
            color: AuroraColors.paper,
            borderRadius: AuroraRadius.modal,
            boxShadow: AuroraShadows.modal,
          ),
          padding: a.all(AuroraSpacing.space8),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: a.of(AuroraSharedSizes.confirmIconCircle),
                  height: a.of(AuroraSharedSizes.confirmIconCircle),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accent,
                      width: AuroraBorders.emphasis,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      glyph,
                      size: a.of(AuroraSharedSizes.confirmIconGlyph),
                      color: accent,
                    ),
                  ),
                ),
                SizedBox(height: a.of(AuroraSpacing.space6)),
                Text(title, style: AuroraSharedType.stateTitle),
                SizedBox(height: a.of(AuroraSpacing.space6)),
                Text(message, style: AuroraSharedType.modalBody),
                if (details != null) ...[
                  SizedBox(height: a.of(AuroraSpacing.space6)),
                  details!,
                ],
                SizedBox(height: a.of(AuroraSpacing.space8)),
                if (stacked) ...[
                  confirmButton,
                  SizedBox(height: a.of(AuroraSpacing.space3)),
                  cancelButton,
                ] else
                  Row(
                    children: [
                      Expanded(flex: _cancelFlex, child: cancelButton),
                      SizedBox(width: a.of(AuroraSpacing.space3)),
                      Expanded(flex: _confirmFlex, child: confirmButton),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
