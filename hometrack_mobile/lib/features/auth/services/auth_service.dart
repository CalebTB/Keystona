import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hometrack_mobile/core/config/supabase_client.dart';
import 'package:hometrack_mobile/features/auth/models/user_model.dart';
import 'package:hometrack_mobile/features/auth/models/auth_result.dart';

class AuthService {
  GoTrueClient get _auth => supabase.auth;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges {
    return _auth.onAuthStateChange.map((state) => state.session?.user);
  }

  Future<AuthResult<UserModel>> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.user == null) {
        return const AuthFailure(UnknownError('Failed to create account'));
      }

      return AuthSuccess(UserModel.fromSupabaseUser(response.user!));
    } on AuthException catch (e) {
      return AuthFailure(_mapAuthException(e));
    } catch (e) {
      return AuthFailure(UnknownError(e.toString()));
    }
  }

  Future<AuthResult<UserModel>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return const AuthFailure(InvalidCredentialsError());
      }

      return AuthSuccess(UserModel.fromSupabaseUser(response.user!));
    } on AuthException catch (e) {
      return AuthFailure(_mapAuthException(e));
    } catch (e) {
      return AuthFailure(UnknownError(e.toString()));
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<AuthResult<void>> sendPasswordResetEmail(String email) async {
    try {
      await _auth.resetPasswordForEmail(email);
      return const AuthSuccess(null);
    } on AuthException catch (e) {
      return AuthFailure(_mapAuthException(e));
    } catch (e) {
      return AuthFailure(UnknownError(e.toString()));
    }
  }

  // Map Supabase AuthException to our error types
  AuthError _mapAuthException(AuthException e) {
    if (e.message.contains('Invalid login credentials')) {
      return const InvalidCredentialsError();
    } else if (e.message.contains('User already registered')) {
      return const EmailAlreadyExistsError();
    } else if (e.message.contains('Password should be')) {
      return const WeakPasswordError();
    } else {
      return UnknownError(e.message);
    }
  }
}
