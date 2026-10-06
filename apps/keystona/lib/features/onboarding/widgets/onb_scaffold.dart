import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_onboarding.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_sizes.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/widgets/aurora/aurora_pressable.dart';
import 'onb_grid_backdrop.dart';

/// Page frame shared by the onboarding screens: grid backdrop, optional
/// progress top bar, a scrolling body, and a footer pinned to the bottom when
/// the content is short.
class OnbScaffold extends StatelessWidget {
  const OnbScaffold({
    super.key,
    required this.content,
    this.footer = const [],
    this.step,
    this.onBack,
  });

  /// Number of steps in the progress bar ("1 OF 3").
  static const int totalSteps = 3;

  /// Content above the footer, spaced 20 pt apart.
  final List<Widget> content;

  /// Buttons at the bottom of the page.
  final List<Widget> footer;

  /// Current step (1-3). Null hides the top bar.
  final int? step;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Scaffold(
      backgroundColor: AuroraColors.paper,
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: OnbGridBackdrop(),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: a.contentMaxWidth),
                child: Column(
                  children: [
                    if (step != null) OnbTopBar(step: step!, onBack: onBack),
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                a.of(AuroraSpacing.space8),
                                a.of(AuroraSpacing.space5),
                                a.of(AuroraSpacing.space8),
                                a.of(AuroraSpacing.space9),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                spacing: a.of(AuroraSpacing.space8),
                                children: [
                                  ...content,
                                  const Expanded(child: SizedBox.shrink()),
                                  if (footer.isNotEmpty)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      spacing: a.of(AuroraSpacing.space2),
                                      children: footer,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Back chevron, progress segments and "N OF 3".
class OnbTopBar extends StatelessWidget {
  const OnbTopBar({super.key, required this.step, this.onBack});

  final int step;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        a.of(AuroraSpacing.space7),
        a.of(AuroraSpacing.space6),
        a.of(AuroraSpacing.space7),
        0,
      ),
      child: Row(
        spacing: a.of(AuroraSpacing.space5),
        children: [
          AuroraPressable(
            onTap: onBack,
            semanticLabel: 'Back',
            enforceTouchTarget: true,
            child: Icon(
              CupertinoIcons.chevron_back,
              size: a.of(AuroraOnbSizes.backGlyph),
              color: AuroraColors.ink,
            ),
          ),
          Expanded(
            child: Semantics(
              label: 'Setup',
              value: '$step of ${OnbScaffold.totalSteps}',
              child: ExcludeSemantics(
                child: Row(
                  spacing: a.of(AuroraSpacing.space2),
                  children: [
                    for (var i = 1; i <= OnbScaffold.totalSteps; i++)
                      Expanded(
                        child: Container(
                          height: a.of(AuroraOnbSizes.stepBarHeight),
                          decoration: BoxDecoration(
                            color: i <= step
                                ? AuroraColors.coral
                                : AuroraColors.paper,
                            borderRadius: AuroraRadius.bar,
                            border: i <= step
                                ? null
                                : Border.all(
                                    color: AuroraColors.inkBorderStrong,
                                    width: AuroraBorders.regular,
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: a.of(AuroraOnbSizes.stepCounterMinWidth),
            ),
            child: Text(
              '$step OF ${OnbScaffold.totalSteps}',
              textAlign: TextAlign.end,
              style: AuroraOnbType.stepCounter,
            ),
          ),
        ],
      ),
    );
  }
}
