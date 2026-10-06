import 'package:flutter/material.dart';

import '../theme/aurora_colors.dart';
import '../theme/aurora_radius.dart';
import '../theme/aurora_scale.dart';
import '../theme/aurora_sizes.dart';
import '../theme/aurora_spacing.dart';
import '../theme/aurora_typography.dart';
import 'aurora/aurora_button.dart';

/// Pattern C — outlined icon circle + title + body + optional CTA.
///
/// Use for standard empty lists and sections. All copy must come from the
/// Empty States Catalog (or the kit screen where one exists: DocsEmpty,
/// ProjectsEmpty, EmergencyEmpty, NotificationsEmpty, TasksCaughtUp).
///
/// Kit look: no fills. The icon sits in an outlined circle, neutral by
/// default and coral when [accent] is set (an empty state that asks for the
/// first item). The CTA is a full-width coral pill; [secondaryLabel] adds the
/// outline pill beneath it.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.accent = false,
    this.secondaryLabel,
    this.onSecondary,
  });

  /// Icon displayed in the outlined circle above the title.
  final IconData icon;

  /// Primary heading text. Use sentence case.
  final String title;

  /// Secondary descriptive text below the title.
  final String subtitle;

  /// Optional label for the action button. When null the button is hidden.
  final String? actionLabel;

  /// Callback for the action button tap.
  final VoidCallback? onAction;

  /// Coral circle outline and icon instead of the neutral one.
  final bool accent;

  /// Optional label for the outline pill under the action.
  final String? secondaryLabel;

  /// Callback for the secondary pill.
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return _EmptyStateBody(
      icon: icon,
      title: title,
      subtitle: subtitle,
      actionLabel: actionLabel,
      onAction: onAction,
      accent: accent,
      secondaryLabel: secondaryLabel,
      onSecondary: onSecondary,
    );
  }
}

/// Pattern A — first-time / zero-state of a primary feature screen.
///
/// Same outlined-circle layout as [EmptyState] with the coral accent and a
/// full-width CTA. (The coral hero disc is not in the kit.)
class EmptyStateHero extends StatelessWidget {
  const EmptyStateHero({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return _EmptyStateBody(
      icon: icon,
      title: title,
      subtitle: subtitle,
      actionLabel: actionLabel,
      onAction: onAction,
      accent: true,
    );
  }
}

class _EmptyStateBody extends StatelessWidget {
  const _EmptyStateBody({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool accent;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final tone = accent ? AuroraColors.coral : AuroraColors.inkSecondary;
    final ring = accent ? AuroraColors.coral : AuroraColors.inkBorderStrong;
    final hasAction = actionLabel != null && onAction != null;
    final hasSecondary = secondaryLabel != null && onSecondary != null;

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
                  width: a.of(AuroraSharedSizes.emptyIconCircle),
                  height: a.of(AuroraSharedSizes.emptyIconCircle),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ring,
                      width: AuroraBorders.regular,
                    ),
                  ),
                  child: Center(
                    child: ExcludeSemantics(
                      child: Icon(
                        icon,
                        size: a.of(AuroraSharedSizes.emptyIconGlyph),
                        color: tone,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: a.of(AuroraSpacing.space7)),
                Text(
                  title,
                  style: AuroraSharedType.stateTitle,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: a.of(AuroraSpacing.space5)),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: a.of(AuroraSharedSizes.bodyMaxWidth),
                  ),
                  child: Text(
                    subtitle,
                    style: AuroraSharedType.stateBody,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (hasAction) ...[
                  SizedBox(height: a.of(AuroraSpacing.space9)),
                  PrimaryButton(
                    label: actionLabel!,
                    onPressed: onAction,
                    expand: true,
                  ),
                ],
                if (hasSecondary) ...[
                  SizedBox(height: a.of(AuroraSpacing.space3)),
                  SecondaryButton(
                    label: secondaryLabel!,
                    onPressed: onSecondary,
                    expand: true,
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

/// Pattern E — inline CTA card.
///
/// Paper card with a hairline border (no tint), outlined icon tile, title,
/// subtitle and a cobalt button. Use for secondary empty states within a
/// screen that already has another primary empty state or for feature upsell
/// sections.
class EmptyStateCta extends StatelessWidget {
  const EmptyStateCta({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Container(
      width: double.infinity,
      padding: a.all(AuroraSpacing.space7),
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: AuroraRadius.xl,
        border: Border.all(
          color: AuroraColors.inkBorder,
          width: AuroraBorders.regular,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: a.of(AuroraSharedSizes.iconTile),
            height: a.of(AuroraSharedSizes.iconTile),
            decoration: BoxDecoration(
              borderRadius: AuroraRadius.tile,
              border: Border.all(
                color: AuroraColors.inkTileBorder,
                width: AuroraBorders.regular,
              ),
            ),
            child: Center(
              child: ExcludeSemantics(
                child: Icon(
                  icon,
                  size: a.of(AuroraIconSizes.md),
                  color: AuroraColors.ink,
                ),
              ),
            ),
          ),
          SizedBox(height: a.of(AuroraSpacing.space5)),
          Text(title, style: AuroraType.h3),
          SizedBox(height: a.of(AuroraSpacing.space2)),
          Text(
            subtitle,
            style: AuroraType.body.copyWith(color: AuroraColors.inkBody),
          ),
          SizedBox(height: a.of(AuroraSpacing.space7)),
          SaveButton(label: actionLabel, onPressed: onAction),
        ],
      ),
    );
  }
}
