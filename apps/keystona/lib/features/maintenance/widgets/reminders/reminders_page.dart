import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';

/// The scrolling frame of a reminder screen: safe area, pull to refresh,
/// content centered and width-capped on wide screens, and an optional footer
/// that stays below the scroll (the "Looks good" bar).
///
/// Short content still scrolls, so pull to refresh always works, and long
/// content, large text or a small phone scroll instead of overflowing.
class RemindersPage extends StatelessWidget {
  const RemindersPage({
    super.key,
    required this.child,
    required this.onRefresh,
    this.footer,
  });

  final Widget child;
  final Future<void> Function() onRefresh;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: a.contentMaxWidth),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            a.of(AuroraSpacing.screenPadH),
            a.of(AuroraSpacing.screenPadTop),
            a.of(AuroraSpacing.screenPadH),
            a.of(AuroraSpacing.screenPadBottom),
          ),
          child: child,
        ),
      ),
    );
    return Scaffold(
      backgroundColor: AuroraColors.paper,
      body: SafeArea(
        bottom: footer == null,
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator.adaptive(
                onRefresh: onRefresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [SliverToBoxAdapter(child: content)],
                ),
              ),
            ),
            ?footer,
          ],
        ),
      ),
    );
  }
}
