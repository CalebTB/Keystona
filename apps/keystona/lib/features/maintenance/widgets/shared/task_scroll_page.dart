import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';

/// The scrolling page frame of the task detail and history screens: safe
/// area, pull to refresh, and content centered and width-capped on wide
/// screens.
///
/// Short content still scrolls (so pull to refresh always works) and long
/// content, large text or a small phone scroll instead of overflowing.
class TaskScrollPage extends StatelessWidget {
  const TaskScrollPage({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  final Widget child;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return SafeArea(
      bottom: false,
      child: RefreshIndicator.adaptive(
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Center(
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
