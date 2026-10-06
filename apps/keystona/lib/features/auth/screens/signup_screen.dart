import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_auth.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../../../services/providers/service_providers.dart';
import '../auth_copy.dart';
import '../widgets/auth_button.dart';
import '../models/password_rules.dart';
import '../providers/auth_provider.dart';
import '../services/auth_error_messages.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_links.dart';
import '../widgets/auth_navigation.dart';
import '../widgets/auth_page.dart';
import '../widgets/password_rule_list.dart';

/// Create your account (kit: AuthSignUp, 1.2).
///
/// "Create account" stays disabled until there is a name, a valid email and a
/// password that meets all three rules. With email confirmation on, sign up
/// returns no session, so the screen moves on to "Check your email"; with it
/// off, the session arrives through the auth stream and the router redirects.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _emailOk => Validators.email(_email.text) == null;

  bool get _ready =>
      _name.text.trim().isNotEmpty &&
      _emailOk &&
      PasswordRules.of(_password.text).allMet;

  Future<void> _submit() async {
    if (!_ready || _loading) return;
    final auth = ref.read(authServiceProvider);
    final email = _email.text.trim();
    setState(() => _loading = true);
    try {
      final response = await auth.signUp(
        email: email,
        password: _password.text,
        fullName: _name.text.trim(),
      );
      if (!mounted) return;
      // No session yet: the account waits on the confirmation email. When a
      // session exists the router redirects away from this screen on its own.
      if (response.session == null) {
        context.go(AppRoutes.checkEmail, extra: email);
      }
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
        const AuthHeader(
          title: AuthCopy.signUpTitle,
          body: AuthCopy.signUpBody,
        ),
        AuthGap(AuroraAuthSizes.sectionGap),
        AuthField(
          label: AuthCopy.nameLabel,
          controller: _name,
          hintText: AuthCopy.namePlaceholder,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          errorFor: (v) => v.trim().isEmpty ? AuthCopy.nameRequired : null,
          onChanged: (_) => setState(() {}),
        ),
        AuthGap(AuroraAuthSizes.fieldGap),
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
          hintText: AuthCopy.signUpPlaceholder,
          password: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
        ),
        AuthGap(AuroraSpacing.space5),
        PasswordRuleList(rules: PasswordRules.of(_password.text)),
      ],
      bottom: [
        AuthGap(AuroraAuthSizes.sectionGap),
        AuthButton(
          label: AuthCopy.createAccount,
          loading: _loading,
          onPressed: _ready ? _submit : null,
        ),
        AuthGap(AuroraAuthSizes.buttonGap),
        AuthLegalLine(
          onTerms: () => openLegalLink(AuthLegalLinks.terms),
          onPrivacy: () => openLegalLink(AuthLegalLinks.privacy),
        ),
      ],
    );
  }
}
