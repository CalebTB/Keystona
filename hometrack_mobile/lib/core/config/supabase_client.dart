import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Custom secure storage implementation for Supabase
class SecureLocalStorage extends LocalStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<void> initialize() async {
    // No initialization needed
  }

  @override
  Future<String?> accessToken() async {
    return await _storage.read(key: 'supabase.auth.token');
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await _storage.write(
      key: 'supabase.auth.token',
      value: persistSessionString,
    );
  }

  @override
  Future<void> removePersistedSession() async {
    await _storage.delete(key: 'supabase.auth.token');
  }

  @override
  Future<bool> hasAccessToken() async {
    final token = await accessToken();
    return token != null;
  }
}

// Initialize Supabase
Future<void> initializeSupabase() async {
  // Get values from environment
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception('Missing Supabase configuration in .env.development file');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      localStorage: SecureLocalStorage(),
    ),
  );
}

// Global Supabase client accessor
SupabaseClient get supabase => Supabase.instance.client;
