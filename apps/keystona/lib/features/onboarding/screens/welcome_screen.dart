import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_auth.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../auth/auth_copy.dart';
import '../../auth/widgets/auth_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/auth_grid.dart';
import '../../auth/widgets/auth_links.dart';
import '../../auth/widgets/auth_logo.dart';
import '../../auth/widgets/auth_navigation.dart';
import '../../auth/widgets/auth_page.dart';
import '../../auth/widgets/social_auth_buttons.dart';

/// Welcome — the first choice a new user makes (kit: AuthWelcome, 1.1).
///
/// Apple and Google start the OAuth flow; the router moves the user on once
/// the session arrives, so those buttons never navigate. "Create an account
/// with email" opens sign up; "Log in" opens log in.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aurora;
    return AuthPage(
      background: const _WelcomeGrid(),
      top: [
        AuthGap(AuroraAuthSizes.welcomeTop),
        Row(
          children: [
            AuthLogoMark(
              size: a.of(AuroraAuthSizes.wordmarkGlyph),
              bodyColor: AuroraColors.coral,
              barColor: AuroraColors.paper,
            ),
            SizedBox(width: a.of(AuroraSpacing.space3)),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(AuthCopy.appName, style: AuroraAuthType.wordmark),
              ),
            ),
          ],
        ),
      ],
      bottom: [
        Semantics(
          header: true,
          child: Text(AuthCopy.welcomeTitle, style: AuroraAuthType.hero),
        ),
        SizedBox(height: a.of(AuroraSpacing.space4)),
        Text(AuthCopy.welcomeBody, style: AuroraAuthType.heroBody),
        AuthGap(AuroraSpacing.formSection),
        const SocialAuthButtons(),
        AuthGap(AuroraAuthSizes.buttonGap),
        AuthButton(
          label: AuthCopy.createWithEmail,
          onPressed: () => context.push(AppRoutes.signup),
        ),
        AuthGap(AuroraSpacing.space1),
        AuthPromptRow(
          prompt: AuthCopy.haveAccount,
          linkLabel: AuthCopy.logInLink,
          onPressed: () => context.push(AppRoutes.login),
        ),
        AuthLegalLine(
          onTerms: () => openLegalLink(AuthLegalLinks.terms),
          onPrivacy: () => openLegalLink(AuthLegalLinks.privacy),
        ),
      ],
    );
  }
}

/// Blueprint grid across the top of the screen, fading out toward the title.
class _WelcomeGrid extends StatelessWidget {
  const _WelcomeGrid();

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: height * AuroraAuthSizes.welcomeGridFraction,
      child: const AuthGrid(
        color: AuroraAuthColors.gridOnPaper,
        cell: AuroraAuthSizes.gridCell,
        fade: AuthGridFade.bottom,
      ),
    );
  }
}
