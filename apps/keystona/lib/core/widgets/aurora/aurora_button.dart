import 'package:flutter/material.dart';

import '../../theme/aurora_colors.dart';
import '../../theme/aurora_radius.dart';
import '../../theme/aurora_scale.dart';
import '../../theme/aurora_sizes.dart';
import '../../theme/aurora_spacing.dart';
import '../../theme/aurora_typography.dart';
import 'aurora_pressable.dart';

/// Fill of a [PrimaryButton].
enum AuroraButtonTone {
  /// Cobalt — the default action color.
  cobalt,

  /// Coral — only for paywall, upgrade and destructive actions.
  coral,
}

/// Shared pill: min-height control, never a fixed height, so large text grows
/// the button instead of clipping it.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.onPressed,
    required this.fill,
    required this.foreground,
    required this.textStyle,
    required this.minHeight,
    required this.horizontalPadding,
    this.loading = false,
    this.expand = false,
    this.borderColor,
    this.enforceTouchTarget = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expand;
  final Color fill;
  final Color foreground;
  final Color? borderColor;
  final TextStyle textStyle;
  final double minHeight;
  final double horizontalPadding;
  final bool enforceTouchTarget;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final enabled = onPressed != null && !loading;
    // A loading button keeps its colors; only a button with no action looks
    // disabled (ink 8% fill, 35% text).
    final showDisabled = onPressed == null && !loading;
    final bg = showDisabled ? AuroraColors.inkDisabledFill : fill;
    final fg = showDisabled ? AuroraColors.inkPlaceholder : foreground;

    final Widget content = loading
        ? SizedBox.square(
            dimension: a.of(AuroraSizes.spinner),
            child: CircularProgressIndicator(
              strokeWidth: AuroraBorders.spinnerStroke,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Text(
            label,
            textAlign: TextAlign.center,
            style: textStyle.copyWith(color: fg),
          );

    return AuroraPressable(
      onTap: enabled ? onPressed : null,
      semanticLabel: label,
      enforceTouchTarget: enforceTouchTarget,
      child: Container(
        constraints: BoxConstraints(
          // A pill with its own 44 pt tap-target wrapper may be drawn smaller
          // (36 pt sheet Save); text growth still expands it.
          minHeight:
              enforceTouchTarget ? a.of(minHeight) : a.minControl(minHeight),
          minWidth: expand ? double.infinity : 0,
        ),
        padding: a.symmetric(horizontal: horizontalPadding),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AuroraRadius.full,
          border: borderColor == null
              ? null
              : Border.all(
                  color: showDisabled
                      ? AuroraColors.inkDisabledFill
                      : borderColor!,
                  width: AuroraBorders.emphasis,
                ),
        ),
        child: Center(widthFactor: 1, heightFactor: 1, child: content),
      ),
    );
  }
}

/// Primary pill — cobalt, 46 pt min height, 15/600 label.
///
/// Use [tone] = [AuroraButtonTone.coral] only for paywall, upgrade and
/// destructive actions. [large] is the 54 pt paywall size.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.expand = false,
    this.tone = AuroraButtonTone.cobalt,
    this.large = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  /// When true, button fills available width.
  final bool expand;

  final AuroraButtonTone tone;

  /// 54 pt instead of 46 pt (paywall / upgrade).
  final bool large;

  @override
  Widget build(BuildContext context) {
    return _Pill(
      label: label,
      onPressed: onPressed,
      loading: loading,
      expand: expand,
      fill: tone == AuroraButtonTone.coral
          ? AuroraColors.coral
          : AuroraColors.cobalt,
      foreground: AuroraColors.paper,
      textStyle: AuroraType.button,
      minHeight:
          large ? AuroraSizes.buttonHeightLg : AuroraSizes.buttonHeight,
      horizontalPadding: AuroraSpacing.pillH,
    );
  }
}

/// Secondary pill — paper fill, 1.5 pt ink 20% border, ink label.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return _Pill(
      label: label,
      onPressed: onPressed,
      expand: expand,
      fill: AuroraColors.paper,
      foreground: AuroraColors.ink,
      borderColor: AuroraColors.inkBorderStrong,
      textStyle: AuroraType.button,
      minHeight: AuroraSizes.buttonHeight,
      horizontalPadding: AuroraSpacing.pillH,
    );
  }
}

/// Cobalt save pill. Disabled (ink 8% fill, 35% text) when [onPressed] is null.
///
/// [compact] is the 36 pt pill used in a sheet header.
class SaveButton extends StatelessWidget {
  const SaveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.expand = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expand;

  /// 36 pt header pill (14/600) instead of the 46 pt button.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _Pill(
      label: label,
      onPressed: onPressed,
      loading: loading,
      expand: expand,
      fill: AuroraColors.cobalt,
      foreground: AuroraColors.paper,
      textStyle: compact ? AuroraType.buttonSm : AuroraType.button,
      minHeight:
          compact ? AuroraSizes.buttonHeightSm : AuroraSizes.buttonHeight,
      horizontalPadding:
          compact ? AuroraSpacing.pillHCompact : AuroraSpacing.pillH,
      enforceTouchTarget: compact,
    );
  }
}

/// Text-only action in cobalt — inline secondary action ("View all", "Edit").
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuroraPressable(
      onTap: onPressed,
      semanticLabel: label,
      enforceTouchTarget: true,
      child: Padding(
        padding: a.symmetric(
          horizontal: AuroraSpacing.space5,
          vertical: AuroraSpacing.space3,
        ),
        child: Text(
          label,
          style: AuroraType.buttonSm.copyWith(
            color: onPressed == null
                ? AuroraColors.inkPlaceholder
                : AuroraColors.cobalt,
          ),
        ),
      ),
    );
  }
}
