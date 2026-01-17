import 'package:flutter_test/flutter_test.dart';
import 'package:hometrack_mobile/features/auth/models/user_model.dart';
import 'package:hometrack_mobile/features/auth/models/auth_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('UserModel', () {
    test('fromSupabaseUser creates correct model', () {
      final user = User(
        id: 'test-id',
        email: 'test@example.com',
        appMetadata: {},
        userMetadata: {'full_name': 'Test User'},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );

      final model = UserModel.fromSupabaseUser(user);

      expect(model.id, 'test-id');
      expect(model.email, 'test@example.com');
      expect(model.fullName, 'Test User');
    });
  });

  group('AuthResult', () {
    test('AuthSuccess contains data', () {
      const result = AuthSuccess<String>('success');

      expect(result, isA<AuthSuccess>());
      expect(result.data, 'success');
    });

    test('AuthFailure contains error', () {
      const result = AuthFailure<String>(NetworkError());

      expect(result, isA<AuthFailure>());
      expect(result.error, isA<NetworkError>());
      expect(result.error.message, contains('internet'));
    });
  });
}
