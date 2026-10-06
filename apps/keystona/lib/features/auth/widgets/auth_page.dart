import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/aurora_auth.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_sizes.dart';

/// Shared frame for the sign-in screens: paper canvas, [top] content pinned to
/// the top and [bottom] actions pinned to the bottom.
///
/// When there is room the two are pushed apart; when the screen is short, the
/// keyboard is open, or text is large the whole page scrolls instead of
/// overflowing. Content is centred and capped on tablets.
class AuthPage extends StatelessWidget {
  const AuthPage({
    super.key,
    required this.top,
    required this.bottom,
    this.background,
  });

  /// Back button, header and form.
  final List<Widget> top;

  /// Primary action, secondary actions and the legal line.
  final List<Widget> bottom;

  /// Painted behind everything (welcome grid).
  final Widget? background;

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Scaffold(
      backgroundColor: AuroraColors.paper,
      body: Stack(
        children: [
          ?background,
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: a.contentMaxWidth),
                child: AutofillGroup(
                  child: CustomScrollView(
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            a.of(AuroraAuthSizes.pagePadH),
                            a.of(AuroraAuthSizes.pagePadTop),
                            a.of(AuroraAuthSizes.pagePadH),
                            a.of(AuroraAuthSizes.pagePadBottom),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [...top, const Spacer(), ...bottom],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A fixed vertical gap read through the responsive layer.
class AuthGap extends StatelessWidget {
  const AuthGap(this.token, {super.key});

  final double token;

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: context.aurora.of(token));
}

/// 44 pt back chevron at the top-left of every sign-in screen.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({
    super.key,
    required this.onPressed,
    required this.label,
  });

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AuroraSizes.minTouch,
              minHeight: AuroraSizes.minTouch,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Icon(
                CupertinoIcons.chevron_back,
                size: context.aurora.of(AuroraAuthSizes.backGlyph),
                color: AuroraColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
