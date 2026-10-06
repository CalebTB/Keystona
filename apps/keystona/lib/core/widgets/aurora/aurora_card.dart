import 'package:flutter/material.dart';

import '../../theme/aurora_colors.dart';
import '../../theme/aurora_radius.dart';
import '../../theme/aurora_scale.dart';
import '../../theme/aurora_shadows.dart';
import '../../theme/aurora_sizes.dart';
import '../../theme/aurora_spacing.dart';
import '../../theme/aurora_typography.dart';
import 'aurora_pressable.dart';

/// Standard content container.
///
/// Paper, 1 pt ink 12% border, 16 radius, 14 padding. No shadow by default.
/// [accentColor] adds the 4 pt colored left rule used on urgent cards and rows
/// (coral overdue, amber soon).
class AuroraCard extends StatelessWidget {
  const AuroraCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.onLongPress,
    this.shadow = false,
    this.accentColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  /// Long-press opens the row's context menu (kit: replaces ⋯ buttons).
  final VoidCallback? onLongPress;

  /// Set [shadow] to add the subtle card lift (opt-in, not default).
  final bool shadow;

  /// Colored left rule. Null for none.
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    Widget body = Padding(
      padding: padding ?? a.all(AuroraSpacing.space6),
      child: child,
    );
    if (accentColor != null) {
      body = ClipRRect(
        borderRadius: AuroraRadius.xl,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(left: AuroraBorders.accentRule),
              child: body,
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: AuroraBorders.accentRule,
              child: ColoredBox(color: accentColor!),
            ),
          ],
        ),
      );
    }
    final inner = DecoratedBox(
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: AuroraRadius.xl,
        border: Border.all(
          color: AuroraColors.inkBorder,
          width: AuroraBorders.regular,
        ),
        boxShadow: shadow ? AuroraShadows.card : null,
      ),
      child: body,
    );

    if (onTap == null && onLongPress == null) return inner;
    return AuroraPressable(onTap: onTap, onLongPress: onLongPress, child: inner);
  }
}

/// Compact tile for stats, quick actions, and mini-callouts.
///
/// Used inside a card or grid — never freestanding. 14 radius, paper with a
/// 1 pt border (no tinted fill). Pass [background] only for a solid brand
/// fill (cobalt, lime, ink); the border is then dropped.
class AuroraTile extends StatelessWidget {
  const AuroraTile({
    super.key,
    required this.child,
    this.background,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final Color? background;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final inner = DecoratedBox(
      decoration: BoxDecoration(
        color: background ?? AuroraColors.paper,
        borderRadius: AuroraRadius.lg,
        border: background == null
            ? Border.all(
                color: AuroraColors.inkBorder,
                width: AuroraBorders.regular,
              )
            : null,
      ),
      child: Padding(
        padding: padding ??
            a.symmetric(
              horizontal: AuroraSpacing.space5,
              vertical: AuroraSpacing.space4,
            ),
        child: child,
      ),
    );
    return onTap == null ? inner : AuroraPressable(onTap: onTap, child: inner);
  }
}

/// Dashboard hero — coral, with the yellow sun spot.
///
/// One coral surface per screen. Displays the home health score, a trend line
/// in lime, and the three pillar scores below a divider. The score stays white
/// whatever its value; urgency lives in the content around it.
class AuroraHeroCard extends StatelessWidget {
  const AuroraHeroCard({
    super.key,
    required this.score,
    required this.trend,
    required this.maintScore,
    required this.docsScore,
    required this.emergScore,
  });

  final int score;

  /// Short trend line, e.g. "↗ Stable this month". Rendered uppercase.
  final String trend;

  final int maintScore;
  final int docsScore;
  final int emergScore;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return ClipRRect(
      borderRadius: AuroraRadius.xxl,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AuroraColors.coral),
        child: Stack(
          children: [
            Positioned(
              top: -a.of(AuroraSizes.heroSunOffset),
              right: -a.of(AuroraSizes.heroSunOffset),
              child: Container(
                width: a.of(AuroraSizes.heroSun),
                height: a.of(AuroraSizes.heroSun),
                decoration: const BoxDecoration(
                  color: AuroraColors.heroSun,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: a.all(AuroraSpacing.space7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'HOME HEALTH',
                    style: AuroraType.label.copyWith(color: AuroraColors.paper),
                  ),
                  SizedBox(height: a.of(AuroraSpacing.space2)),
                  Text(
                    '$score',
                    style: AuroraType.displayXl.copyWith(
                      color: AuroraColors.paper,
                    ),
                  ),
                  SizedBox(height: a.of(AuroraSpacing.space2)),
                  Text(
                    trend.toUpperCase(),
                    style: AuroraType.label.copyWith(
                      color: AuroraColors.lime,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: a.of(AuroraSpacing.space5)),
                  const Divider(
                    height: AuroraBorders.hairline,
                    thickness: AuroraBorders.hairline,
                    color: AuroraColors.onCoralTrack,
                  ),
                  SizedBox(height: a.of(AuroraSpacing.space5)),
                  Row(
                    children: [
                      Expanded(
                        child: _Pillar(label: 'MAINT.', value: maintScore),
                      ),
                      Expanded(child: _Pillar(label: 'DOCS', value: docsScore)),
                      Expanded(
                        child: _Pillar(label: 'EMERG.', value: emergScore),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pillar extends StatelessWidget {
  const _Pillar({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AuroraType.labelSm.copyWith(color: AuroraColors.paper),
        ),
        SizedBox(height: a.of(AuroraSpacing.space1)),
        Text(
          '$value',
          style: AuroraType.h3.copyWith(color: AuroraColors.paper),
        ),
      ],
    );
  }
}
