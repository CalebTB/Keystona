import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';

/// The scrolling frame of an item screen: safe area, content centered and
/// width-capped on wide screens, and pull to refresh when [onRefresh] is
/// given.
///
/// Short content still scrolls, so a small phone, large text or landscape
/// scroll instead of overflowing. A [fill] (an empty or error state) takes the
/// space left under [child] and centers itself in it.
class ItemPage extends StatelessWidget {
  const ItemPage({
    super.key,
    required this.child,
    this.onRefresh,
    this.fill,
  });

  final Widget child;
  final Future<void> Function()? onRefresh;
  final Widget? fill;

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
    final scroll = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: content),
        if (fill != null)
          SliverFillRemaining(hasScrollBody: false, child: fill),
      ],
    );
    final refresh = onRefresh;
    return Scaffold(
      backgroundColor: AuroraColors.paper,
      body: SafeArea(
        child: refresh == null
            ? scroll
            : RefreshIndicator.adaptive(onRefresh: refresh, child: scroll),
      ),
    );
  }
}
