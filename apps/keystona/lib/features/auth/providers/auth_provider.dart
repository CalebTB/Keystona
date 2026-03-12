import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
