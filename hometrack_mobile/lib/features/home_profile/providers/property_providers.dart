import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hometrack_mobile/core/config/supabase_client.dart';
import 'package:hometrack_mobile/features/home_profile/services/property_service.dart';
import 'package:hometrack_mobile/features/home_profile/models/property.dart';
import 'package:hometrack_mobile/features/home_profile/models/property_result.dart';

/// Property service provider
final propertyServiceProvider = Provider<PropertyService>((ref) {
  return PropertyService();
});

/// User properties provider
///
/// Uses FutureProvider instead of StreamProvider for simplicity.
/// Properties rarely change (user-initiated only), so realtime subscriptions
/// are unnecessary. Manual refresh via ref.invalidate after mutations.
final userPropertiesProvider = FutureProvider<List<Property>>((ref) async {
  final client = supabase;
  final user = client.auth.currentUser;

  if (user == null) {
    throw const UnauthorizedError();
  }

  final response = await client
      .from('properties')
      .select()
      .eq('user_id', user.id)
      .order('created_at', ascending: false);

  return (response as List).map((json) => Property.fromJson(json)).toList();
});

/// Selected property provider for viewing/editing
final selectedPropertyProvider = StateProvider<Property?>((ref) => null);

/// Helper provider to refresh property list after mutations
///
/// Usage: ref.read(refreshPropertiesProvider)()
final refreshPropertiesProvider = Provider<void Function()>((ref) {
  return () => ref.invalidate(userPropertiesProvider);
});
