import 'package:flutter/material.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_onboarding.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_sizes.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/aurora/aurora_button.dart';
import '../../../core/widgets/aurora/aurora_pressable.dart';

/// Eyebrow, 30 pt title and subtitle at the top of a screen.
class OnbHeader extends StatelessWidget {
  const OnbHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.badge,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;

  /// Optional pill above the title.
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: a.of(AuroraSpacing.space3),
      children: [
        ?badge,
        if (eyebrow != null)
          Text(eyebrow!.toUpperCase(), style: AuroraOnbType.eyebrow),
        Semantics(
          header: true,
          child: Text(title, style: AuroraOnbType.title),
        ),
        if (subtitle != null) Text(subtitle!, style: AuroraOnbType.subtitle),
      ],
    );
  }
}

/// The big coral button at the bottom of an onboarding screen.
///
/// The kit draws every onboarding button coral (act now). Change [tone] here
/// to flip all five screens to cobalt.
class OnbCta extends StatelessWidget {
  const OnbCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  static const AuroraButtonTone tone = AuroraButtonTone.coral;

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: label,
      onPressed: onPressed,
      loading: loading,
      expand: true,
      large: true,
      tone: tone,
    );
  }
}

/// Quiet text link under the main button. 44 pt tall.
class OnbTextLink extends StatelessWidget {
  const OnbTextLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AuroraPressable(
      onTap: onTap,
      semanticLabel: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AuroraSizes.minTouch),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AuroraOnbType.link,
          ),
        ),
      ),
    );
  }
}

/// A card the user picks one of. Selected draws a [selectedColor] border.
class OnbChoiceCard extends StatelessWidget {
  const OnbChoiceCard({
    super.key,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
    required this.child,
    required this.semanticLabel,
    this.radius = AuroraRadius.xl,
    this.padding,
  });

  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Widget child;
  final String semanticLabel;
  final BorderRadius radius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: AuroraPressable(
        onTap: onTap,
        selected: selected,
        semanticLabel: semanticLabel,
        child: Container(
          padding: padding ?? a.all(AuroraSpacing.space6),
          decoration: BoxDecoration(
            color: AuroraColors.paper,
            borderRadius: radius,
            border: Border.all(
              color: selected ? selectedColor : AuroraColors.inkInputBorder,
              width: selected
                  ? AuroraOnbSizes.selectedBorder
                  : AuroraBorders.regular,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A bordered group of rows split by hairlines.
class OnbRowGroup extends StatelessWidget {
  const OnbRowGroup({super.key, required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: AuroraRadius.xl,
        border: Border.all(
          color: AuroraColors.inkBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: ClipRRect(
        borderRadius: AuroraRadius.xl,
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: AuroraBorders.hairline,
                  thickness: AuroraBorders.hairline,
                  color: AuroraColors.inkBorder,
                ),
              rows[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Uppercase section label with an optional trailing note.
class OnbSectionHeader extends StatelessWidget {
  const OnbSectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Semantics(
            header: true,
            child: Text(title.toUpperCase(), style: AuroraType.label),
          ),
        ),
        if (trailing != null)
          Flexible(
            child: Text(
              trailing!.toUpperCase(),
              textAlign: TextAlign.end,
              style: AuroraType.meta,
            ),
          ),
      ],
    );
  }
}
