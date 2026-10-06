import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_auth.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_sizes.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../../../services/providers/service_providers.dart';
import '../auth_copy.dart';
import '../widgets/auth_button.dart';
import '../providers/auth_provider.dart';
import '../services/auth_error_messages.dart';
import '../widgets/auth_grid.dart';
import '../widgets/auth_links.dart';
import '../widgets/auth_navigation.dart';
import '../widgets/auth_page.dart';
import '../widgets/auth_sent_banner.dart';

/// Check your email (kit: AuthCheckEmail, 1.3).
///
/// Shown after sign up while the account waits on its confirmation link.
/// "Resend email" sends it again, then holds for a cooldown that counts down
/// in the status strip before the button comes back.
class CheckEmailScreen extends ConsumerStatefulWidget {
  const CheckEmailScreen({super.key, required this.email});

  /// Address the confirmation link was sent to.
  final String email;

  @override
  ConsumerState<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends ConsumerState<CheckEmailScreen> {
  Timer? _timer;
  int _cooldown = 0;
  bool _resending = false;

  bool get _cooling => _cooldown > 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    if (_resending || _cooling) return;
    final auth = ref.read(authServiceProvider);
    setState(() => _resending = true);
    try {
      await auth.resendSignupEmail(widget.email);
      if (!mounted) return;
      _startCooldown();
    } catch (e) {
      if (!mounted) return;
      final reason = AuthErrorMessages.from(e);
      SnackbarService.showError(
        context,
        AuthCopy.errorResend,
        subtitle: reason == AuthCopy.errorGeneric ? null : reason,
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = AuroraAuthTiming.resendCooldownSeconds);
    _timer = Timer.periodic(AuroraAuthTiming.tick, (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _cooldown -= 1);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  Future<void> _openMail() async {
    final open = ref.read(mailAppLauncherProvider);
    final opened = await open();
    if (!mounted) return;
    if (!opened) SnackbarService.showInfo(context, AuthCopy.errorNoMail);
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuthPage(
      top: [
        AuthBackButton(
          label: AuthCopy.back,
          onPressed: () => authBack(context, AppRoutes.signup),
        ),
        AuthGap(AuroraAuthSizes.checkTop),
        Column(
          children: [
            const _MailTile(),
            AuthGap(AuroraAuthSizes.checkGap),
            Semantics(
              header: true,
              child: Text(
                AuthCopy.checkTitle,
                textAlign: TextAlign.center,
                style: AuroraAuthType.title,
              ),
            ),
            SizedBox(height: a.of(AuroraAuthSizes.titleGap)),
            Text.rich(
              TextSpan(
                style: AuroraAuthType.subtitle,
                children: [
                  const TextSpan(text: AuthCopy.checkLeadIn),
                  TextSpan(
                    text: widget.email,
                    style: AuroraAuthType.subtitle.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AuroraColors.ink,
                    ),
                  ),
                  const TextSpan(text: AuthCopy.checkLeadOut),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ],
      bottom: [
        AuthGap(AuroraAuthSizes.sectionGap),
        AuthButton(label: AuthCopy.openMail, onPressed: _openMail),
        AuthGap(AuroraAuthSizes.buttonGap),
        if (_cooling)
          AuthSentStrip(message: AuthCopy.sentAgain(_cooldown))
        else
          AuthButton(
            label: AuthCopy.resendEmail,
            style: AuthButtonStyle.secondary,
            loading: _resending,
            onPressed: _resend,
          ),
        AuthTextLink(
          label: AuthCopy.differentEmail,
          style: AuroraAuthType.quiet,
          onPressed: () => authBack(context, AppRoutes.signup),
        ),
      ],
    );
  }
}

/// Coral-outlined grid tile with an envelope.
class _MailTile extends StatelessWidget {
  const _MailTile();

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final edge = a.of(AuroraAuthSizes.checkTile);
    final radius = BorderRadius.circular(a.of(AuroraAuthSizes.checkTileRadius));
    return ExcludeSemantics(
      child: Container(
        width: edge,
        height: edge,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: AuroraAuthColors.coralOutline,
            width: AuroraBorders.regular,
          ),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const AuthGrid(
                color: AuroraAuthColors.gridOnPaper,
                cell: AuroraAuthSizes.tileGridCell,
              ),
              Center(
                child: Icon(
                  CupertinoIcons.mail,
                  size: a.of(AuroraAuthSizes.checkGlyph),
                  color: AuroraColors.coral,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
