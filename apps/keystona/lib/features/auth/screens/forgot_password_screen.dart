import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_auth.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_sizes.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../../../services/providers/service_providers.dart';
import '../auth_copy.dart';
import '../widgets/auth_button.dart';
import '../services/auth_error_messages.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_links.dart';
import '../widgets/auth_navigation.dart';
import '../widgets/auth_page.dart';
import '../widgets/auth_sent_banner.dart';

/// Reset your password (kit: AuthForgot, 1.5).
///
/// Two states: asking for the email, and "Check your inbox" once the link has
/// been sent. The wording never says whether the address has an account.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  bool get _ready => Validators.email(_email.text) == null;

  Future<void> _send() async {
    if (!_ready || _loading) return;
    final auth = ref.read(authServiceProvider);
    setState(() => _loading = true);
    try {
      await auth.resetPassword(_email.text.trim());
      if (!mounted) return;
      setState(() => _sent = true);
    } catch (e) {
      if (!mounted) return;
      SnackbarService.showError(context, AuthErrorMessages.from(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return AuthPage(
      top: [
        AuthBackButton(
          label: AuthCopy.back,
          onPressed: () => authBack(context, AppRoutes.login),
        ),
        AuthGap(AuroraAuthSizes.sectionGap),
        const AuthHeader(
          title: AuthCopy.forgotTitle,
          body: AuthCopy.forgotBody,
        ),
        AuthGap(AuroraAuthSizes.sectionGap),
        if (_sent)
          AuthSentCard(
            title: AuthCopy.checkInbox,
            body: TextSpan(
              children: [
                const TextSpan(text: AuthCopy.forgotSentLeadIn),
                TextSpan(
                  text: _email.text.trim(),
                  style: AuroraAuthType.sentBody.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AuroraColors.ink,
                  ),
                ),
                const TextSpan(text: AuthCopy.forgotSentLeadOut),
              ],
            ),
          )
        else
          AuthField(
            label: AuthCopy.emailLabel,
            controller: _email,
            hintText: AuthCopy.emailPlaceholder,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            errorFor: (v) => v.isNotEmpty && Validators.email(v) != null
                ? AuthCopy.emailInvalid
                : null,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _send(),
          ),
        AuthGap(AuroraAuthSizes.sectionGap),
        Container(
          padding: EdgeInsets.only(top: a.of(AuroraSpacing.space6)),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: AuroraColors.inkBorder,
                width: AuroraBorders.hairline,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                CupertinoIcons.info,
                size: a.of(AuroraAuthSizes.hintGlyph),
                color: AuroraColors.inkSecondary,
              ),
              SizedBox(width: a.of(AuroraSpacing.space4)),
              Expanded(
                child: Text(
                  AuthCopy.forgotHint,
                  style: AuroraAuthType.sentBody,
                ),
              ),
            ],
          ),
        ),
      ],
      bottom: [
        AuthGap(AuroraAuthSizes.sectionGap),
        if (_sent) ...[
          AuthButton(
            label: AuthCopy.backToLogIn,
            onPressed: () => context.go(AppRoutes.login),
          ),
          AuthTextLink(
            label: AuthCopy.differentEmail,
            style: AuroraAuthType.quiet,
            onPressed: () => setState(() => _sent = false),
          ),
        ] else
          AuthButton(
            label: AuthCopy.sendResetLink,
            loading: _loading,
            onPressed: _ready ? _send : null,
          ),
      ],
    );
  }
}
