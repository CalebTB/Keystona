import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/providers/service_providers.dart';

/// Streams every [AuthState] event emitted by Supabase (sign-in, sign-out,
/// token refresh). The router listens to this provider so the redirect
/// logic re-evaluates on every auth transition.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).onAuthStateChange;
});

/// Synchronous boolean derived from [AuthService.isAuthenticated].
///
/// Watches [authStateProvider] so this provider — and the router — invalidate
/// on every auth event (sign-in, sign-out, token refresh).
final isAuthenticatedProvider = Provider<bool>((ref) {
  ref.watch(authStateProvider);
  return ref.read(authServiceProvider).isAuthenticated;
});

/// Opens the device's mail app. Returns false when none could be opened.
///
/// A provider so tests can replace it. iOS opens Mail through the `message`
/// scheme; everywhere else the `mailto` scheme opens the default mail app.
final mailAppLauncherProvider = Provider<Future<bool> Function()>((ref) {
  return () async {
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    final uri = Uri(
      scheme: isIos ? 'message' : 'mailto',
      path: isIos ? '/' : '',
    );
    try {
      return await launchUrl(uri);
    } catch (_) {
      return false;
    }
  };
});

/// Where "Terms" and "Privacy policy" open.
///
/// Both are null until the legal pages have URLs; the links render but do
/// nothing yet. // note: set these when the pages are published.
abstract final class AuthLegalLinks {
  static final Uri? terms = null;
  static final Uri? privacy = null;
}
