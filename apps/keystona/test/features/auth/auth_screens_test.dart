import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/core/widgets/aurora/aurora_pressable.dart';
import 'package:keystona/features/auth/auth_copy.dart';
import 'package:keystona/features/auth/models/password_rules.dart';
import 'package:keystona/features/auth/screens/check_email_screen.dart';
import 'package:keystona/features/auth/screens/forgot_password_screen.dart';
import 'package:keystona/features/auth/screens/login_screen.dart';
import 'package:keystona/features/auth/screens/signup_screen.dart';
import 'package:keystona/features/auth/screens/splash_screen.dart';
import 'package:keystona/features/onboarding/screens/welcome_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_test_support.dart';

/// Whether the pill labelled [label] reacts to taps.
bool _enabled(WidgetTester tester, String label) {
  final pressable = find
      .ancestor(of: find.text(label), matching: find.byType(AuroraPressable))
      .first;
  return tester.widget<AuroraPressable>(pressable).onTap != null;
}

Future<void> _type(WidgetTester tester, int index, String text) async {
  await tester.enterText(find.byType(TextField).at(index), text);
  await tester.pump();
}

void main() {
  late FakeAuthService auth;
  setUp(() => auth = FakeAuthService());

  group('PasswordRules', () {
    test('needs length, both cases and a number', () {
      expect(PasswordRules.of('abc').allMet, isFalse);
      expect(PasswordRules.of('abcdefgh').mixedCase, isFalse);
      expect(PasswordRules.of('Abcdefgh').number, isFalse);
      expect(PasswordRules.of('Abcdefg1').allMet, isTrue);
    });
  });

  group('SplashScreen', () {
    testWidgets('shows the brand and moves to welcome after the hold', (
      tester,
    ) async {
      await tester.pumpWidget(routerApp(const SplashScreen(), auth));
      expect(find.text(AuthCopy.appName), findsOneWidget);
      expect(find.text(AuthCopy.tagline), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.textContaining('route:/welcome'), findsOneWidget);
    });

    testWidgets('tap skips the wait', (tester) async {
      await tester.pumpWidget(routerApp(const SplashScreen(), auth));
      await tester.tap(find.bySemanticsLabel(AuthCopy.continueLabel));
      await tester.pumpAndSettle();
      expect(find.textContaining('route:/welcome'), findsOneWidget);
    });
  });

  group('WelcomeScreen', () {
    testWidgets('shows the kit copy', (tester) async {
      await tester.pumpWidget(routerApp(const WelcomeScreen(), auth));
      expect(find.text(AuthCopy.welcomeBody), findsOneWidget);
      expect(find.text(AuthCopy.continueWithApple), findsOneWidget);
      expect(find.text(AuthCopy.continueWithGoogle), findsOneWidget);
      expect(find.text(AuthCopy.createWithEmail), findsOneWidget);
      expect(find.text(AuthCopy.logInLink), findsOneWidget);
    });

    testWidgets('email and log in open their screens', (tester) async {
      await tester.pumpWidget(routerApp(const WelcomeScreen(), auth));
      await tester.tap(find.text(AuthCopy.createWithEmail));
      await tester.pumpAndSettle();
      expect(find.textContaining('route:/signup'), findsOneWidget);
    });

    testWidgets('Apple and Google start OAuth', (tester) async {
      await tester.pumpWidget(routerApp(const WelcomeScreen(), auth));
      await tester.tap(find.text(AuthCopy.continueWithApple));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AuthCopy.continueWithGoogle));
      await tester.pumpAndSettle();
      expect(auth.calls, ['apple', 'google']);
    });

    testWidgets('a failed OAuth start shows an error snackbar', (tester) async {
      auth.failWith = const AuthException('boom');
      await tester.pumpWidget(routerApp(const WelcomeScreen(), auth));
      await tester.tap(find.text(AuthCopy.continueWithApple));
      await tester.pumpAndSettle();
      expect(find.text(AuthCopy.errorApple), findsOneWidget);
    });

    testWidgets('an OAuth flow that does not launch also errors', (
      tester,
    ) async {
      auth.oauthLaunches = false;
      await tester.pumpWidget(routerApp(const WelcomeScreen(), auth));
      await tester.tap(find.text(AuthCopy.continueWithGoogle));
      await tester.pumpAndSettle();
      expect(find.text(AuthCopy.errorGoogle), findsOneWidget);
    });
  });

  group('SignupScreen', () {
    testWidgets('Create account is disabled until everything is valid', (
      tester,
    ) async {
      await tester.pumpWidget(routerApp(const SignupScreen(), auth));
      expect(_enabled(tester, AuthCopy.createAccount), isFalse);
      await _type(tester, 0, 'Jordan Smith');
      await _type(tester, 1, 'jordan@example.com');
      await _type(tester, 2, 'short');
      expect(_enabled(tester, AuthCopy.createAccount), isFalse);
      await _type(tester, 2, 'Abcdefg1');
      expect(_enabled(tester, AuthCopy.createAccount), isTrue);
    });

    testWidgets('shows the three rules', (tester) async {
      await tester.pumpWidget(routerApp(const SignupScreen(), auth));
      expect(find.text(AuthCopy.ruleLength), findsOneWidget);
      expect(find.text(AuthCopy.ruleCase), findsOneWidget);
      expect(find.text(AuthCopy.ruleNumber), findsOneWidget);
    });

    testWidgets('Show reveals the password', (tester) async {
      await tester.pumpWidget(routerApp(const SignupScreen(), auth));
      TextField field() => tester.widget(find.byType(TextField).at(2));
      expect(field().obscureText, isTrue);
      await tester.tap(find.text(AuthCopy.show));
      await tester.pump();
      expect(field().obscureText, isFalse);
      expect(find.text(AuthCopy.hide), findsOneWidget);
    });

    testWidgets('a bad email is flagged after the field is left', (
      tester,
    ) async {
      await tester.pumpWidget(routerApp(const SignupScreen(), auth));
      await tester.tap(find.byType(TextField).at(1));
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(1), 'nope');
      await tester.pump();
      expect(find.text(AuthCopy.emailInvalid), findsNothing);
      await tester.tap(find.byType(TextField).at(2));
      await tester.pump();
      expect(find.text(AuthCopy.emailInvalid), findsOneWidget);
    });

    testWidgets('submit without a session goes to check your email', (
      tester,
    ) async {
      await tester.pumpWidget(routerApp(const SignupScreen(), auth));
      await _type(tester, 0, 'Jordan Smith');
      await _type(tester, 1, 'jordan@example.com');
      await _type(tester, 2, 'Abcdefg1');
      await tester.tap(find.text(AuthCopy.createAccount));
      await tester.pumpAndSettle();
      expect(auth.calls, ['signUp:jordan@example.com']);
      expect(
        find.text('route:/check-email:jordan@example.com'),
        findsOneWidget,
      );
    });

    testWidgets('a failure stays on the screen and shows a snackbar', (
      tester,
    ) async {
      auth.failWith = const AuthException(
        'User already registered',
        code: 'user_already_exists',
      );
      await tester.pumpWidget(routerApp(const SignupScreen(), auth));
      await _type(tester, 0, 'Jordan Smith');
      await _type(tester, 1, 'jordan@example.com');
      await _type(tester, 2, 'Abcdefg1');
      await tester.tap(find.text(AuthCopy.createAccount));
      await tester.pumpAndSettle();
      expect(find.text(AuthCopy.errorExists), findsOneWidget);
      expect(find.text(AuthCopy.signUpTitle), findsOneWidget);
    });
  });

  group('LoginScreen', () {
    testWidgets('Log in needs a valid email and a password', (tester) async {
      await tester.pumpWidget(routerApp(const LoginScreen(), auth));
      expect(_enabled(tester, AuthCopy.logInLink), isFalse);
      await _type(tester, 0, 'jordan@example.com');
      expect(_enabled(tester, AuthCopy.logInLink), isFalse);
      await _type(tester, 1, 'x');
      expect(_enabled(tester, AuthCopy.logInLink), isTrue);
    });

    testWidgets('signs in without navigating', (tester) async {
      await tester.pumpWidget(routerApp(const LoginScreen(), auth));
      await _type(tester, 0, 'jordan@example.com');
      await _type(tester, 1, 'pw');
      await tester.tap(find.text(AuthCopy.logInLink));
      await tester.pumpAndSettle();
      expect(auth.calls, ['signIn:jordan@example.com']);
      expect(find.text(AuthCopy.logInTitle), findsOneWidget);
    });

    testWidgets('wrong credentials show a plain message', (tester) async {
      auth.failWith = const AuthException(
        'Invalid login credentials',
        code: 'invalid_credentials',
      );
      await tester.pumpWidget(routerApp(const LoginScreen(), auth));
      await _type(tester, 0, 'jordan@example.com');
      await _type(tester, 1, 'pw');
      await tester.tap(find.text(AuthCopy.logInLink));
      await tester.pumpAndSettle();
      expect(find.text(AuthCopy.errorCredentials), findsOneWidget);
    });

    testWidgets('Forgot password opens reset, Create an account goes welcome', (
      tester,
    ) async {
      await tester.pumpWidget(routerApp(const LoginScreen(), auth));
      await tester.tap(find.text(AuthCopy.forgotPassword));
      await tester.pumpAndSettle();
      expect(find.textContaining('route:/forgot-password'), findsOneWidget);
    });

    testWidgets('has Apple and Google buttons', (tester) async {
      await tester.pumpWidget(routerApp(const LoginScreen(), auth));
      await tester.tap(find.text(AuthCopy.continueWithGoogle));
      await tester.pumpAndSettle();
      expect(auth.calls, ['google']);
    });
  });

  group('ForgotPasswordScreen', () {
    testWidgets('sends the link then shows the inbox card', (tester) async {
      await tester.pumpWidget(routerApp(const ForgotPasswordScreen(), auth));
      expect(_enabled(tester, AuthCopy.sendResetLink), isFalse);
      await _type(tester, 0, 'jordan@example.com');
      expect(_enabled(tester, AuthCopy.sendResetLink), isTrue);
      await tester.tap(find.text(AuthCopy.sendResetLink));
      await tester.pumpAndSettle();
      expect(auth.calls, ['reset:jordan@example.com']);
      expect(find.text(AuthCopy.checkInbox), findsOneWidget);
      expect(find.text(AuthCopy.backToLogIn), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      // The Apple / Google hint stays visible in both states.
      expect(find.text(AuthCopy.forgotHint), findsOneWidget);
    });

    testWidgets('Use a different email returns to the form', (tester) async {
      await tester.pumpWidget(routerApp(const ForgotPasswordScreen(), auth));
      await _type(tester, 0, 'jordan@example.com');
      await tester.tap(find.text(AuthCopy.sendResetLink));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AuthCopy.differentEmail));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('a failure keeps the form and shows a snackbar', (
      tester,
    ) async {
      auth.failWith = const AuthException(
        'x',
        code: 'over_email_send_rate_limit',
      );
      await tester.pumpWidget(routerApp(const ForgotPasswordScreen(), auth));
      await _type(tester, 0, 'jordan@example.com');
      await tester.tap(find.text(AuthCopy.sendResetLink));
      await tester.pumpAndSettle();
      expect(find.text(AuthCopy.errorRateLimit), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('CheckEmailScreen', () {
    testWidgets('names the address and offers the three actions', (
      tester,
    ) async {
      await tester.pumpWidget(
        routerApp(const CheckEmailScreen(email: 'jordan@example.com'), auth),
      );
      expect(find.textContaining('jordan@example.com'), findsOneWidget);
      expect(find.text(AuthCopy.openMail), findsOneWidget);
      expect(find.text(AuthCopy.resendEmail), findsOneWidget);
      expect(find.text(AuthCopy.differentEmail), findsOneWidget);
    });

    testWidgets('resend sends once, then counts down and returns', (
      tester,
    ) async {
      await tester.pumpWidget(
        routerApp(const CheckEmailScreen(email: 'jordan@example.com'), auth),
      );
      await tester.tap(find.text(AuthCopy.resendEmail));
      await tester.pump();
      await tester.pump();
      expect(auth.calls, ['resend:jordan@example.com']);
      expect(find.text(AuthCopy.sentAgain(60)), findsOneWidget);
      expect(find.text(AuthCopy.resendEmail), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(AuthCopy.sentAgain(59)), findsOneWidget);
      await tester.pump(const Duration(seconds: 60));
      expect(find.text(AuthCopy.resendEmail), findsOneWidget);
    });

    testWidgets('Open Mail with no mail app shows a notice', (tester) async {
      await tester.pumpWidget(
        routerApp(
          const CheckEmailScreen(email: 'jordan@example.com'),
          auth,
          openMail: () async => false,
        ),
      );
      await tester.tap(find.text(AuthCopy.openMail));
      await tester.pumpAndSettle();
      expect(find.text(AuthCopy.errorNoMail), findsOneWidget);
    });

    testWidgets('a failed resend shows an error and keeps the button', (
      tester,
    ) async {
      auth.failWith = const AuthException('x');
      await tester.pumpWidget(
        routerApp(const CheckEmailScreen(email: 'jordan@example.com'), auth),
      );
      await tester.tap(find.text(AuthCopy.resendEmail));
      await tester.pumpAndSettle();
      expect(find.text(AuthCopy.errorResend), findsOneWidget);
      expect(find.text(AuthCopy.resendEmail), findsOneWidget);
    });

    testWidgets('Use a different email goes back to sign up', (tester) async {
      await tester.pumpWidget(
        routerApp(const CheckEmailScreen(email: 'jordan@example.com'), auth),
      );
      await tester.tap(find.text(AuthCopy.differentEmail));
      await tester.pumpAndSettle();
      expect(find.textContaining('route:/signup'), findsOneWidget);
    });
  });
}
