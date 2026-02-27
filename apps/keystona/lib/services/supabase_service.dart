import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin accessor for the Supabase client singleton.
///
/// Use [SupabaseService.client] anywhere a [SupabaseClient] is needed instead
/// of calling [Supabase.instance.client] directly. This makes it easy to swap
/// or mock the client in tests.
abstract final class SupabaseService {
  /// The globally initialized [SupabaseClient] instance.
  ///
  /// [Supabase.initialize] must have been called in [main] before
  /// accessing this getter.
  static SupabaseClient get client => Supabase.instance.client;
}
