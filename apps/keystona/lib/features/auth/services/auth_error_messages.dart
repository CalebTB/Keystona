import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth_copy.dart';

/// Turns whatever a sign-in call threw into one plain sentence for a snackbar.
///
/// Never returns the raw exception text (it can carry an email address).
abstract final class AuthErrorMessages {
  static String from(Object error) {
    if (error is SocketException) return AuthCopy.errorOffline;
    if (error is AuthRetryableFetchException) return AuthCopy.errorOffline;
    if (error is AuthException) {
      final text = error.message.toLowerCase();
      final code = (error.code ?? '').toLowerCase();
      if (code == 'invalid_credentials' || text.contains('invalid login')) {
        return AuthCopy.errorCredentials;
      }
      if (code == 'user_already_exists' ||
          text.contains('already registered') ||
          text.contains('already been registered')) {
        return AuthCopy.errorExists;
      }
      if (code == 'email_not_confirmed' || text.contains('not confirmed')) {
        return AuthCopy.errorUnconfirmed;
      }
      if (code == 'weak_password' || text.contains('password should be')) {
        return AuthCopy.errorWeakPassword;
      }
      if (code.contains('rate_limit') ||
          text.contains('rate limit') ||
          text.contains('too many')) {
        return AuthCopy.errorRateLimit;
      }
    }
    return AuthCopy.errorGeneric;
  }
}
