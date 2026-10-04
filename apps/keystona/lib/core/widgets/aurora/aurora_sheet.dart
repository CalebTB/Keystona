import 'package:flutter/material.dart';

import '../../theme/aurora_breakpoints.dart';
import '../../theme/aurora_colors.dart';
import '../../theme/aurora_radius.dart';
import '../../theme/aurora_spacing.dart';
import '../../theme/aurora_typography.dart';
import 'aurora_button.dart';

/// Target sheet height as a fraction of screen height.
///
/// Values from `Keystona_Aurora_Component_Library.md` §3.3. Pick by use case
/// per §3.1: source pickers [compact], date/share [medium], most sub-forms
/// [tall], photo-grid sub-forms [extra]. [full] is a last resort — push a
/// full screen instead.
enum AuroraSheetHeight {
  compact(0.35),
  medium(0.50),
  tall(0.70),
  extra(0.85),
  full(0.95);

  const AuroraSheetHeight(this.fraction);

  /// Fraction of screen height on [AuroraDeviceClass.regular].
  final double fraction;

  /// Resolved height in logical pixels for this device class.
  ///
  /// Compact phones get a little more of the screen (the spec percentages are
  /// tuned for a 390pt-wide phone, and a 35% sheet on an SE is cramped).
  /// Tablets get less, because 70% of an iPad is an absurd amount of sheet.
  double resolve(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final adjusted = switch (AuroraBreakpoints.of(context)) {
      AuroraDeviceClass.compact => (fraction + 0.05).clamp(0.0, 0.95),
      AuroraDeviceClass.regular => fraction,
      AuroraDeviceClass.tablet => (fraction - 0.10).clamp(0.0, 0.95),
    };
    return size.height * adjusted;
  }
}

/// One row in [AuroraSheet.actionSheet] — per Component Library §3.6.
class AuroraSheetAction {
  const AuroraSheetAction({
    required this.label,
    this.icon,
    this.destructive = false,
  });

  final String label;
  final IconData? icon;

  /// Renders the label in coral, e.g. "Delete document".
  final bool destructive;
}

/// Bottom sheet following Aurora Design System v2.0.
///
/// Implements the anatomy in `Keystona_Aurora_Component_Library.md` §3.2
/// (drag handle, title row, divider, body padding), the height tokens in
/// §3.3, and the widget contract in §3.7.
///
/// Prefer this over calling `showModalBottomSheet` directly — the sheet's
/// corner radius, backdrop, handle and padding are all resolved here, so
/// they stay consistent and responsive without any decoration at call sites.
abstract final class AuroraSheet {
  /// Backdrop scrim — §3.2. Lighter than a modal; sheets are less interruptive.
  static final Color _backdrop = AuroraColors.ink.withValues(alpha: 0.45);

  /// Top corner radius, responsive by device class.
  ///
  /// Spec baseline is 22px (`radius-2xl`) on a regular phone. Compact phones
  /// tighten to 18px so the sheet doesn't eat its own title row; tablets open
  /// up to 28px to stay proportionate against a much larger surface.
  static BorderRadius topRadius(BuildContext context) {
    final r = switch (AuroraBreakpoints.of(context)) {
      AuroraDeviceClass.compact => 18.0,
      AuroraDeviceClass.regular => 22.0,
      AuroraDeviceClass.tablet => 28.0,
    };
    return BorderRadius.vertical(top: Radius.circular(r));
  }

  /// Standard sheet. Returns the value passed to `Navigator.pop`.
  ///
  /// [title] renders the §3.2 title row (Cancel left, title centre, confirm
  /// right). Omit it for a bare sheet with just a handle. [confirmLabel] and
  /// [onConfirm] add the cobalt pill on the right.
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    String? confirmLabel,
    VoidCallback? onConfirm,
    AuroraSheetHeight height = AuroraSheetHeight.tall,
    bool dismissOnBackdropTap = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: dismissOnBackdropTap,
      enableDrag: true,
      backgroundColor: AuroraColors.paper,
      barrierColor: _backdrop,
      constraints: _constraints(context),
      shape: RoundedRectangleBorder(borderRadius: topRadius(context)),
      builder: (ctx) => SizedBox(
        height: height.resolve(ctx),
        child: _SheetFrame(
          title: title,
          confirmLabel: confirmLabel,
          onConfirm: onConfirm,
          child: child,
        ),
      ),
    );
  }

  /// Content-height sheet — no fixed fraction, hugs its child.
  ///
  /// Use for short, self-sizing content. Caps at [AuroraSheetHeight.extra] so
  /// an unexpectedly long child still scrolls instead of overflowing.
  static Future<T?> showAuto<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    String? confirmLabel,
    VoidCallback? onConfirm,
    bool dismissOnBackdropTap = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: dismissOnBackdropTap,
      enableDrag: true,
      backgroundColor: AuroraColors.paper,
      barrierColor: _backdrop,
      constraints: _constraints(context),
      shape: RoundedRectangleBorder(borderRadius: topRadius(context)),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: AuroraSheetHeight.extra.resolve(ctx),
        ),
        child: _SheetFrame(
          title: title,
          confirmLabel: confirmLabel,
          onConfirm: onConfirm,
          shrinkWrap: true,
          child: child,
        ),
      ),
    );
  }

  /// iOS-style action list — §3.6. Resolves to the tapped action's index,
  /// or `null` if cancelled.
  static Future<int?> actionSheet(
    BuildContext context, {
    required String title,
    required List<AuroraSheetAction> actions,
    String cancelLabel = 'Cancel',
  }) {
    return showAuto<int>(
      context,
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < actions.length; i++)
            _ActionRow(
              action: actions[i],
              onTap: () => Navigator.of(context).pop(i),
            ),
          const Divider(height: 1, thickness: 0.5, color: AuroraColors.inkBorder),
          const SizedBox(height: AuroraSpacing.space3),
          GhostButton(
            label: cancelLabel,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Tablets centre the sheet rather than stretching full-width.
  static BoxConstraints? _constraints(BuildContext context) =>
      AuroraBreakpoints.isTablet(context)
          ? const BoxConstraints(
              maxWidth: AuroraBreakpoints.tabletSheetMaxWidth,
            )
          : null;
}

/// Sheet chrome — handle, optional title row, divider, padded body (§3.2).
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.child,
    this.title,
    this.confirmLabel,
    this.onConfirm,
    this.shrinkWrap = false,
  });

  final Widget child;
  final String? title;
  final String? confirmLabel;
  final VoidCallback? onConfirm;

  /// When true the body sizes to content instead of filling the sheet.
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: EdgeInsets.fromLTRB(
        AuroraSpacing.screenPadH,
        AuroraSpacing.space7,
        AuroraSpacing.screenPadH,
        AuroraSpacing.screenPadBottom + MediaQuery.paddingOf(context).bottom,
      ),
      child: child,
    );

    return Column(
      mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
      children: [
        const _DragHandle(),
        if (title != null) ...[
          _TitleRow(
            title: title!,
            confirmLabel: confirmLabel,
            onConfirm: onConfirm,
          ),
          const Divider(height: 1, thickness: 0.5, color: AuroraColors.inkBorder),
        ],
        if (shrinkWrap)
          Flexible(child: SingleChildScrollView(child: body))
        else
          Expanded(child: SingleChildScrollView(child: body)),
      ],
    );
  }
}

/// 4×36 handle, ink-border-strong, 8px from the top of the sheet (§3.2).
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AuroraSpacing.space3),
      width: 36,
      height: 4,
      decoration: const BoxDecoration(
        color: AuroraColors.inkBorderStrong,
        borderRadius: AuroraRadius.full,
      ),
    );
  }
}

/// Cancel (left) · title (centre) · confirm pill (right) — 12px below handle.
class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.title,
    this.confirmLabel,
    this.onConfirm,
  });

  final String title;
  final String? confirmLabel;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final hasConfirm = confirmLabel != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AuroraSpacing.screenPadH,
        AuroraSpacing.space5,
        AuroraSpacing.screenPadH,
        AuroraSpacing.space5,
      ),
      child: Row(
        children: [
          GhostButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              title,
              style: AuroraType.h3.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasConfirm)
            SaveButton(label: confirmLabel!, onPressed: onConfirm)
          else
          // Balances the Cancel button so the title stays optically centred.
            const SizedBox(width: 64),
        ],
      ),
    );
  }
}

/// 56px action row — §3.6.
class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.action, required this.onTap});

  final AuroraSheetAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = action.destructive ? AuroraColors.coral : AuroraColors.ink;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            if (action.icon != null) ...[
              Icon(action.icon, size: 24, color: color),
              const SizedBox(width: AuroraSpacing.space5),
            ],
            Expanded(
              child: Text(
                action.label,
                style: AuroraType.body.copyWith(color: color),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: AuroraColors.inkTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
