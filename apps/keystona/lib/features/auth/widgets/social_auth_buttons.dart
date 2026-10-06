import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/aurora_auth.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../../../services/providers/service_providers.dart';
import '../auth_copy.dart';
import '../services/auth_error_messages.dart';
import 'auth_button.dart';

enum _Provider { apple, google }

/// "Continue with Apple" and "Continue with Google".
///
/// Starts the OAuth flow and, while it launches, shows a spinner on the tapped
/// button and disables both. The session arrives through the auth stream and
/// the router moves the user on, so this never navigates.
class SocialAuthButtons extends ConsumerStatefulWidget {
  const SocialAuthButtons({super.key});

  @override
  ConsumerState<SocialAuthButtons> createState() => _SocialAuthButtonsState();
}

class _SocialAuthButtonsState extends ConsumerState<SocialAuthButtons> {
  _Provider? _busy;

  Future<void> _start(_Provider provider) async {
    if (_busy != null) return;
    final auth = ref.read(authServiceProvider);
    setState(() => _busy = provider);
    try {
      final launched = provider == _Provider.apple
          ? await auth.signInWithApple()
          : await auth.signInWithGoogle();
      if (!mounted) return;
      if (!launched) _fail(provider);
    } catch (e) {
      if (!mounted) return;
      _fail(provider, error: e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _fail(_Provider provider, {Object? error}) {
    final reason = error == null ? null : AuthErrorMessages.from(error);
    SnackbarService.showError(
      context,
      provider == _Provider.apple ? AuthCopy.errorApple : AuthCopy.errorGoogle,
      subtitle: reason == AuthCopy.errorGeneric ? null : reason,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: context.aurora.of(AuroraAuthSizes.buttonGap));
    final idle = _busy == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthButton(
          label: AuthCopy.continueWithApple,
          style: AuthButtonStyle.apple,
          loading: _busy == _Provider.apple,
          onPressed: idle ? () => _start(_Provider.apple) : null,
        ),
        gap,
        AuthButton(
          label: AuthCopy.continueWithGoogle,
          style: AuthButtonStyle.google,
          loading: _busy == _Provider.google,
          onPressed: idle ? () => _start(_Provider.google) : null,
        ),
      ],
    );
  }
}
