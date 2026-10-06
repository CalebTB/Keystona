/// The three password rules shown on sign up, evaluated as the user types.
class PasswordRules {
  const PasswordRules({
    required this.length,
    required this.mixedCase,
    required this.number,
  });

  /// Fewest characters a password may have.
  static const int minLength = 8;

  factory PasswordRules.of(String password) => PasswordRules(
    length: password.length >= minLength,
    mixedCase:
        RegExp('[A-Z]').hasMatch(password) &&
        RegExp('[a-z]').hasMatch(password),
    number: RegExp(r'\d').hasMatch(password),
  );

  final bool length;
  final bool mixedCase;
  final bool number;

  bool get allMet => length && mixedCase && number;
}
