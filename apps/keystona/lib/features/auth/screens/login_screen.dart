import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_auth.dart';
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
import '../widgets/social_auth_buttons.dart';

/// Log in (kit: AuthLogIn, 1.4).
///
/// "Log in" stays disabled until the email is valid and a password is typed.
/// A successful sign in changes the auth stream and the router redirects, so
/// this screen never navigates on success.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _ready =>
      Validators.email(_email.text) == null && _password.text.isNotEmpty;

  Future<void> _submit() async {
    if (!_ready || _loading) return;
    final auth = ref.read(authServiceProvider);
    setState(() => _loading = true);
    try {
      await auth.signIn(email: _email.text.trim(), password: _password.text);
    } catch (e) {
      if (!mounted) return;
      SnackbarService.showError(context, AuthErrorMessages.from(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      top: [
        AuthBackButton(
          label: AuthCopy.back,
          onPressed: () => authBack(context, AppRoutes.welcome),
        ),
        AuthGap(AuroraAuthSizes.sectionGap),
        const AuthHeader(title: AuthCopy.logInTitle, body: AuthCopy.logInBody),
        AuthGap(AuroraAuthSizes.sectionGap),
        const SocialAuthButtons(),
        AuthGap(AuroraAuthSizes.sectionGap),
        const AuthDivider(label: AuthCopy.orWithEmail),
        AuthGap(AuroraAuthSizes.sectionGap),
        AuthField(
          label: AuthCopy.emailLabel,
          controller: _email,
          hintText: AuthCopy.emailPlaceholder,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          errorFor: (v) => v.isNotEmpty && Validators.email(v) != null
              ? AuthCopy.emailInvalid
              : null,
          onChanged: (_) => setState(() {}),
        ),
        AuthGap(AuroraAuthSizes.fieldGap),
        AuthField(
          label: AuthCopy.passwordLabel,
          controller: _password,
          hintText: AuthCopy.logInPlaceholder,
          password: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
        ),
        AuthTextLink(
          label: AuthCopy.forgotPassword,
          style: AuroraAuthType.linkSm,
          alignment: AlignmentDirectional.centerEnd,
          onPressed: () => context.push(AppRoutes.forgotPassword),
        ),
      ],
      bottom: [
        AuthGap(AuroraAuthSizes.sectionGap),
        AuthButton(
          label: AuthCopy.logInLink,
          loading: _loading,
          onPressed: _ready ? _submit : null,
        ),
        AuthPromptRow(
          prompt: AuthCopy.newToKeystona,
          linkLabel: AuthCopy.createAnAccount,
          onPressed: () => context.go(AppRoutes.welcome),
        ),
      ],
    );
  }
}
