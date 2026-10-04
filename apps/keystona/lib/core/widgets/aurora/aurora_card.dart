import 'package:flutter/material.dart';

import '../../theme/aurora_colors.dart';
import '../../theme/aurora_radius.dart';
import '../../theme/aurora_spacing.dart';
import '../../theme/aurora_shadows.dart';
import '../../theme/aurora_typography.dart';

/// Standard content container.
///
/// White background, 1px inkBorder, 16px radius, 14px padding.
/// No shadow by default — Aurora is a flat system.
class AuroraCard extends StatelessWidget {
  const AuroraCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.shadow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  /// Set [shadow] to add the subtle card lift (opt-in, not default).
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: AuroraRadius.xl,
        border: Border.all(color: AuroraColors.inkBorder),
        boxShadow: shadow ? AuroraShadows.card : null,
      ),
      padding: padding ?? const EdgeInsets.all(AuroraSpacing.space6),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: inner);
    }
    return inner;
  }
}

/// Compact tile for stats, quick actions, and mini-callouts.
///
/// Used inside a card or grid — never freestanding. 14px radius, no border.
/// [background] defaults to [AuroraColors.butter]. Other valid fills:
/// cobalt (save/info), lime (success/done), coralDim (alert).
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
    final inner = Container(
      decoration: BoxDecoration(
        color: background ?? AuroraColors.butter,
        borderRadius: AuroraRadius.lg,
      ),
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AuroraSpacing.space5,
            vertical: AuroraSpacing.space4,
          ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: inner);
    }
    return inner;
  }
}

/// Dashboard hero — coral background with yellow decorative blob.
///
/// One per screen, never two stacked. Displays the home health score,
/// a trend label in lime, and the three pillar scores below a divider.
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
    return Container(
      decoration: const BoxDecoration(
        color: AuroraColors.coral,
        borderRadius: AuroraRadius.xxl,
      ),
      child: ClipRRect(
        borderRadius: AuroraRadius.xxl,
        child: Stack(
          children: [
            // Decorative yellow blob
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: AuroraColors.yellow.withValues(alpha: 0.32),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AuroraSpacing.space7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'HOME HEALTH',
                    style: AuroraType.label.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$score',
                    style: AuroraType.displayXl.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    trend.toUpperCase(),
                    style: AuroraType.label.copyWith(
                      color: AuroraColors.lime,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AuroraSpacing.space5),
                  Container(height: 0.5, color: Colors.white.withValues(alpha: 0.20)),
                  const SizedBox(height: AuroraSpacing.space5),
                  Row(
                    children: [
                      Expanded(
                        child: _Pillar(label: 'MAINT.', value: maintScore),
                      ),
                      Expanded(
                        child: _Pillar(label: 'DOCS', value: docsScore),
                      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AuroraType.labelSm.copyWith(
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '$value',
          style: AuroraType.h3.copyWith(color: Colors.white),
        ),
      ],
    );
  }
}
