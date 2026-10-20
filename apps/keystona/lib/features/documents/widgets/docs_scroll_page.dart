import 'package:flutter/material.dart';

import '../../../core/theme/aurora_docs_a.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';

/// The scrolling page frame shared by the Docs screens: safe area, pull to refresh, and content that is centered and width-capped on
/// wide screens.
///
/// Short content still scrolls (so pull to refresh always works) and long
/// content, large text or a small phone scroll instead of overflowing.
class DocsScrollPage extends StatelessWidget {
  const DocsScrollPage({
    super.key,
    required this.child,
    required this.onRefresh,
    this.topPadding,
    this.fillRemaining = false,
  });

  final Widget child;
  final Future<void> Function() onRefresh;

  /// Space above the content. Defaults to the Docs tab's page top.
  final double? topPadding;

  /// Lets [child] take the rest of the viewport (error and empty views that
  /// center themselves).
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
            a.of(topPadding ?? AuroraDocsA.pageTop),
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
