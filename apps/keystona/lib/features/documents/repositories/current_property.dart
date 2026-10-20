import 'package:supabase_flutter/supabase_flutter.dart';

/// The signed-in user's primary property id, or null when they have none yet
/// (onboarding incomplete) or are signed out. Every document query filters by
/// this first.
Future<String?> currentPropertyId(SupabaseClient client) async {
  final user = client.auth.currentUser;
  if (user == null) return null;
  final row = await client
      .from('properties')
      .select('id')
      .eq('user_id', user.id)
      .isFilter('deleted_at', null)
      .order('created_at', ascending: false)
      .limit(1)
      .maybeSingle();
  return row?['id'] as String?;
}
