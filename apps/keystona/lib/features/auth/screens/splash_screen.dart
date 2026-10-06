import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_auth.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../auth_copy.dart';
import '../widgets/auth_grid.dart';
import '../widgets/auth_logo.dart';

/// First screen on a cold start (kit: OnbSplash, 1.0).
///
/// Holds for [AuroraAuthTiming.splashHold], then moves to
/// welcome. Tapping anywhere skips the wait.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(AuroraAuthTiming.splashHold, _continue);
  }

  void _continue() {
    _timer?.cancel();
    if (!mounted) return;
    context.go(AppRoutes.welcome);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Scaffold(
      backgroundColor: AuroraColors.coral,
      body: Semantics(
        button: true,
        label: AuthCopy.continueLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _continue,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const AuthGrid(
                color: AuroraAuthColors.gridOnCoral,
                cell: AuroraAuthSizes.gridCell,
                fade: AuthGridFade.radial,
              ),
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(child: _SplashMark()),
                      ),
                    ),
                    _SplashBar(),
                    SizedBox(height: a.of(AuroraAuthSizes.splashBarBottom)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: a.of(AuroraAuthSizes.splashTile),
          height: a.of(AuroraAuthSizes.splashTile),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AuroraColors.paper,
            borderRadius: BorderRadius.circular(
              a.of(AuroraAuthSizes.splashTileRadius),
            ),
            boxShadow: [
              BoxShadow(
                color: AuroraAuthColors.logoShadow,
                blurRadius: a.of(AuroraAuthSizes.splashShadowBlur),
                offset: Offset(0, a.of(AuroraAuthSizes.splashShadowOffset)),
              ),
            ],
          ),
          child: AuthLogoMark(
            size: a.of(AuroraAuthSizes.splashGlyph),
            bodyColor: AuroraColors.coral,
            barColor: AuroraColors.paper,
          ),
        ),
        SizedBox(height: a.of(AuroraSpacing.space7)),
        Text(AuthCopy.appName, style: AuroraAuthType.splashWordmark),
        SizedBox(height: a.of(AuroraSpacing.space7)),
        Padding(
          padding: a.symmetric(horizontal: AuroraSpacing.space9),
          child: Text(
            AuthCopy.tagline,
            textAlign: TextAlign.center,
            style: AuroraAuthType.splashTagline,
          ),
        ),
      ],
    );
  }
}

/// Thin progress bar, drawn at the kit's fill.
class _SplashBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return ExcludeSemantics(
      child: Container(
        width: a.of(AuroraAuthSizes.splashBarWidth),
        height: a.of(AuroraAuthSizes.splashBarHeight),
        decoration: const BoxDecoration(
          color: AuroraAuthColors.onCoralTrack,
          borderRadius: AuroraRadius.bar,
        ),
        child: ClipRRect(
          borderRadius: AuroraRadius.bar,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: AuroraAuthSizes.splashBarFill,
              heightFactor: 1,
              child: const ColoredBox(color: AuroraColors.paper),
            ),
          ),
        ),
      ),
    );
  }
}
