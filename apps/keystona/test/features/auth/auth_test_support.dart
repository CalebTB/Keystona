import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:keystona/core/router/app_router.dart';
import 'package:keystona/features/auth/providers/auth_provider.dart';
import 'package:keystona/services/auth_service.dart';
import 'package:keystona/services/providers/service_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// In-memory stand-in for [AuthService]: records calls, never touches Supabase.
class FakeAuthService implements AuthService {
  final List<String> calls = [];
  Object? failWith;
  Session? sessionOnSignUp;
  bool oauthLaunches = true;

  Future<T> _run<T>(String name, T value) async {
    calls.add(name);
    if (failWith != null) throw failWith!;
    return value;
  }

  @override
  User? get currentUser => null;

  @override
  bool get isAuthenticated => false;

  @override
  Stream<AuthState> get onAuthStateChange => const Stream.empty();

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) => _run('signUp:$email', AuthResponse(session: sessionOnSignUp));

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) => _run('signIn:$email', AuthResponse());

  @override
  Future<void> signOut() => _run('signOut', null);

  @override
  Future<void> resetPassword(String email) => _run('reset:$email', null);

  @override
  Future<bool> signInWithApple() => _run('apple', oauthLaunches);

  @override
  Future<bool> signInWithGoogle() => _run('google', oauthLaunches);

  @override
  Future<void> resendSignupEmail(String email) => _run('resend:$email', null);
}

/// Provider overrides every auth screen test uses.
List<Override> authOverrides(
  FakeAuthService auth, {
  Future<bool> Function()? openMail,
}) => [
  authServiceProvider.overrideWithValue(auth),
  if (openMail != null) mailAppLauncherProvider.overrideWithValue(openMail),
];

/// Mounts [home] at [initial] inside a router that knows every auth route.
/// Other routes render a marker with their path so navigation can be asserted.
Widget routerApp(
  Widget home,
  FakeAuthService auth, {
  String initial = '/start',
  Future<bool> Function()? openMail,
}) {
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/start', builder: (_, _) => home),
      for (final path in [
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.signup,
        AppRoutes.forgotPassword,
        AppRoutes.checkEmail,
      ])
        GoRoute(
          path: path,
          builder: (_, state) =>
              Scaffold(body: Text('route:$path:${state.extra ?? ''}')),
        ),
    ],
  );
  return ProviderScope(
    overrides: authOverrides(auth, openMail: openMail),
    child: MaterialApp.router(routerConfig: router),
  );
}
