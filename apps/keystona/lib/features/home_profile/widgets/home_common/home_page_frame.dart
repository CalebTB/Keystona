import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';

/// The scrolling frame of a Home profile screen: safe area, pull to refresh
/// when [onRefresh] is given, content centered and width-capped on wide
/// screens, and an optional [footer] that stays below the scroll.
///
/// Short content still scrolls, so pull to refresh always works and large
/// text or a small phone scroll instead of overflowing.
class HomePageFrame extends StatelessWidget {
  const HomePageFrame({
    super.key,
    required this.child,
    this.onRefresh,
    this.footer,
    this.horizontalPadding = true,
  });

  final Widget child;
  final Future<void> Function()? onRefresh;
  final Widget? footer;

  /// False when the child pads itself (full-bleed rows).
  final bool horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final inset = horizontalPadding ? a.of(AuroraSpacing.screenPadH) : 0.0;
    final content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: a.contentMaxWidth),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            inset,
            a.of(AuroraSpacing.screenPadTop),
            inset,
            a.of(AuroraSpacing.screenPadBottom),
          ),
          child: child,
        ),
      ),
    );
    final scroll = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [SliverToBoxAdapter(child: content)],
    );
    return Scaffold(
      backgroundColor: AuroraColors.paper,
      body: SafeArea(
        bottom: footer == null,
        child: Column(
          children: [
            Expanded(
              child: onRefresh == null
                  ? scroll
                  : RefreshIndicator.adaptive(
                      onRefresh: onRefresh!,
                      child: scroll,
                    ),
            ),
            ?footer,
          ],
        ),
      ),
    );
  }
}
