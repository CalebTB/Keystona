// Sealed class pattern for auth errors
sealed class AuthResult<T> {
  const AuthResult();
}

class AuthSuccess<T> extends AuthResult<T> {
  final T data;
  const AuthSuccess(this.data);
}

class AuthFailure<T> extends AuthResult<T> {
  final AuthError error;
  const AuthFailure(this.error);
}

// Specific error types
sealed class AuthError {
  final String message;
  const AuthError(this.message);
}

class NetworkError extends AuthError {
  const NetworkError() : super('No internet connection. Please try again.');
}

class InvalidCredentialsError extends AuthError {
  const InvalidCredentialsError() : super('Invalid email or password.');
}

class EmailAlreadyExistsError extends AuthError {
  const EmailAlreadyExistsError() : super('An account with this email already exists.');
}

class WeakPasswordError extends AuthError {
  const WeakPasswordError() : super('Password must be at least 8 characters.');
}

class UnknownError extends AuthError {
  const UnknownError(String message) : super(message);
}
