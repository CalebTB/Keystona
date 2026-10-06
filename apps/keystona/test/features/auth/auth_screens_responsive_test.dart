import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystona/features/auth/screens/check_email_screen.dart';
import 'package:keystona/features/auth/screens/forgot_password_screen.dart';
import 'package:keystona/features/auth/screens/login_screen.dart';
import 'package:keystona/features/auth/screens/signup_screen.dart';
import 'package:keystona/features/auth/screens/splash_screen.dart';
import 'package:keystona/features/onboarding/screens/welcome_screen.dart';

import '../../support/responsive_harness.dart';
import 'auth_test_support.dart';

Widget _scoped(Widget child) =>
    ProviderScope(overrides: authOverrides(FakeAuthService()), child: child);

void main() {
  testResponsive('SplashScreen', () => const SplashScreen());
  testResponsive('WelcomeScreen', () => const WelcomeScreen(), wrap: _scoped);
  testResponsive('SignupScreen', () => const SignupScreen(), wrap: _scoped);
  testResponsive('LoginScreen', () => const LoginScreen(), wrap: _scoped);
  testResponsive(
    'ForgotPasswordScreen',
    () => const ForgotPasswordScreen(),
    wrap: _scoped,
  );
  testResponsive(
    'CheckEmailScreen',
    () =>
        const CheckEmailScreen(email: 'jordan.smith.long.address@example.com'),
    wrap: _scoped,
  );
}
