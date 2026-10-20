import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/theme/aurora_tasks_a.dart';

/// The scrolling frame of the Tasks screens: safe area, pull to refresh, and
/// content centered and width-capped on wide screens.
///
/// Short content still scrolls (so pull to refresh always works) and long
/// content, large text or a small phone scroll instead of overflowing.
class TasksScrollPage extends StatelessWidget {
  const TasksScrollPage({
    super.key,
    required this.child,
    required this.onRefresh,
    this.topPadding = AuroraTasksA.pageTop,
    this.fillRemaining = false,
  });

  final Widget child;
  final Future<void> Function() onRefresh;

  /// Space above the content (token, scaled here).
  final double topPadding;

  /// Lets [child] take the rest of the viewport (centered error view).
  final bool fillRemaining;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: a.contentMaxWidth),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            a.of(AuroraSpacing.screenPadH),
            a.of(topPadding),
            a.of(AuroraSpacing.screenPadH),
            a.of(AuroraSpacing.screenPadBottom),
          ),
          child: child,
        ),
      ),
    );

    return SafeArea(
      bottom: false,
      child: RefreshIndicator.adaptive(
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (fillRemaining)
              SliverFillRemaining(hasScrollBody: false, child: content)
            else
              SliverToBoxAdapter(child: content),
          ],
        ),
      ),
    );
  }
}
