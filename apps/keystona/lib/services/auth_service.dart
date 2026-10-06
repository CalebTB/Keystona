import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Handles all Supabase authentication operations.
///
/// Every method throws on failure — callers are responsible for catching
/// exceptions and displaying them via [SnackbarService]. This keeps the
/// service layer free of UI concerns.
///
/// Never log user credentials or PII in this class.
class AuthService {
  final _client = SupabaseService.client;

  /// The currently signed-in user, or null if not authenticated.
  User? get currentUser => _client.auth.currentUser;

  /// True when a user session is active.
  bool get isAuthenticated => currentUser != null;

  /// Stream that emits [AuthState] events on sign-in, sign-out, and refresh.
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  /// Creates a new account with email/password and saves display name metadata.
  ///
  /// Also upserts a row into `profiles` with the provided [fullName].
  /// Throws [AuthException] on failure.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': fullName},
    );

    // With email confirmation on there is no session yet, so a profiles write
    // would be rejected by RLS. The name travels as user metadata until then.
    final userId = response.user?.id;
    if (userId != null && response.session != null) {
      await _client.from('profiles').upsert({
        'id': userId,
        'display_name': fullName,
        'email': email,
      });
    }

    return response;
  }

  /// Signs in an existing user with email and password.
  ///
  /// Throws [AuthException] on invalid credentials or network failure.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Signs out the current user and clears the local session.
  ///
  /// Throws on network failure when the server cannot be reached.
  Future<void> signOut() {
    return _client.auth.signOut();
  }

  /// Sends a password reset email to [email].
  ///
  /// Throws [AuthException] if the email is not registered.
  Future<void> resetPassword(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }

  /// Deep link Supabase returns to after a browser OAuth flow.
  ///
  /// The matching URL scheme must be registered natively and added to the
  /// Supabase redirect allow-list before Apple/Google can complete.
  static const String oauthRedirectUrl = 'io.supabase.keystona://login-callback/';

  /// Starts the Sign in with Apple flow (browser based).
  ///
  /// The session arrives through [onAuthStateChange]; the router redirects.
  /// Returns false when the flow could not be launched. Throws [AuthException].
  Future<bool> signInWithApple() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: oauthRedirectUrl,
    );
  }

  /// Starts the Sign in with Google flow (browser based).
  ///
  /// The session arrives through [onAuthStateChange]; the router redirects.
  /// Returns false when the flow could not be launched. Throws [AuthException].
  Future<bool> signInWithGoogle() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: oauthRedirectUrl,
    );
  }

  /// Sends the signup confirmation email to [email] again.
  ///
  /// Throws [AuthException] on failure or rate limiting.
  Future<void> resendSignupEmail(String email) {
    return _client.auth.resend(type: OtpType.signup, email: email);
  }
}
