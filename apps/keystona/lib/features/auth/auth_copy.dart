/// Copy for the sign-in screens, exactly as written in the kit
/// (`design/source/Auth*.dc.html`, `OnbSplash.dc.html`).
abstract final class AuthCopy {
  // Brand
  static const String appName = 'Keystona';
  static const String tagline = 'THE FULL RECORD OF YOUR HOME';
  static const String continueLabel = 'Continue';

  // Welcome
  static const String welcomeTitle = 'The full record\nof your home.';
  static const String welcomeBody =
      'Maintenance, documents and projects — kept in one place and always up to date.';
  static const String continueWithApple = 'Continue with Apple';
  static const String continueWithGoogle = 'Continue with Google';
  static const String createWithEmail = 'Create an account with email';
  static const String haveAccount = 'Already have an account?';
  static const String logInLink = 'Log in';

  // Legal line
  static const String legalLead = 'BY CONTINUING YOU AGREE TO THE ';
  static const String legalTerms = 'TERMS';
  static const String legalAnd = ' AND ';
  static const String legalPrivacy = 'PRIVACY POLICY';

  // Shared fields
  static const String back = 'Back';
  static const String nameLabel = 'Name';
  static const String namePlaceholder = 'Jordan Smith';
  static const String emailLabel = 'Email';
  static const String emailPlaceholder = 'you@example.com';
  static const String passwordLabel = 'Password';
  static const String show = 'Show';
  static const String hide = 'Hide';
  static const String showPassword = 'Show password';
  static const String hidePassword = 'Hide password';
  static const String nameRequired = 'Name is required';
  static const String emailInvalid = 'Enter a valid email address';

  // Sign up
  static const String signUpTitle = 'Create your account';
  static const String signUpBody =
      "Takes a minute. We'll send a link to confirm your email next.";
  static const String signUpPlaceholder = 'At least 8 characters';
  static const String passwordNeeds = 'Password needs';
  static const String ruleLength = '8 or more characters';
  static const String ruleCase = 'An uppercase and a lowercase letter';
  static const String ruleNumber = 'A number';
  static const String createAccount = 'Create account';

  // Check your email
  static const String checkTitle = 'Check your email';
  static const String checkLeadIn = 'We sent a link to ';
  static const String checkLeadOut =
      '. Tap it to finish setting up your account.';
  static const String openMail = 'Open Mail';
  static const String resendEmail = 'Resend email';
  static const String differentEmail = 'Use a different email';

  /// "Sent again · you can resend in 60s" with the live countdown.
  static String sentAgain(int seconds) =>
      'Sent again · you can resend in ${seconds}s';

  // Log in
  static const String logInTitle = 'Welcome back';
  static const String logInBody = 'Log in the same way you signed up.';
  static const String orWithEmail = 'OR WITH EMAIL';
  static const String logInPlaceholder = 'Your password';
  static const String forgotPassword = 'Forgot password?';
  static const String newToKeystona = 'New to Keystona?';
  static const String createAnAccount = 'Create an account';

  // Forgot password
  static const String forgotTitle = 'Reset your password';
  static const String forgotBody =
      "Enter the email you signed up with and we'll send a link to set a new one.";
  static const String forgotHint =
      "Signed up with Apple or Google? You don't have a Keystona password — just log in with that button.";
  static const String sendResetLink = 'Send reset link';
  static const String checkInbox = 'Check your inbox';
  static const String forgotSentLeadIn = 'If ';
  static const String forgotSentLeadOut =
      ' has an account, a reset link is on its way. It expires in 1 hour.';
  static const String backToLogIn = 'Back to log in';

  // Errors and notices (not in the kit; plain words, never raw exceptions)
  static const String errorGeneric = 'Something went wrong. Try again.';
  static const String errorCredentials = 'That email or password is not right.';
  static const String errorExists =
      'That email already has an account. Try logging in.';
  static const String errorUnconfirmed =
      'Confirm your email first. Check your inbox for the link.';
  static const String errorRateLimit =
      'Too many tries. Wait a minute and try again.';
  static const String errorOffline =
      'No connection. Check your internet and try again.';
  static const String errorWeakPassword =
      'Choose a stronger password and try again.';
  static const String errorApple = "We couldn't start Sign in with Apple.";
  static const String errorGoogle = "We couldn't start Sign in with Google.";
  static const String errorNoMail = 'No mail app found on this device.';
  static const String errorResend = "We couldn't resend the email.";
}
