import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../services/supabase_service.dart';

// ─── Step tracker ─────────────────────────────────────────────────────────────
// Steps: welcome(0), property(1), trial(2), complete(3)
final onboardingStepProvider = StateProvider<int>((ref) => 0);

// ─── Property notifier ────────────────────────────────────────────────────────

class PropertyNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Inserts a new property row for the currently authenticated user.
  ///
  /// [data] must match the `properties` table columns. The `user_id` is
  /// injected here — callers must not include it in [data].
  Future<void> saveProperty(Map<String, dynamic> data) async {
    state = const AsyncLoading();

    final uid = SupabaseService.client.auth.currentUser!.id;
    final payload = Map<String, dynamic>.from(data)..['user_id'] = uid;

    state = await AsyncValue.guard(() async {
      await SupabaseService.client.from('properties').insert(payload);
    });
  }
}

final propertyProvider =
    AsyncNotifierProvider<PropertyNotifier, void>(PropertyNotifier.new);

// ─── Complete onboarding helper ───────────────────────────────────────────────

/// Marks onboarding as done in `users_metadata`.
///
/// Call this before navigating to the dashboard from any onboarding screen.
Future<void> completeOnboarding() async {
  final uid = SupabaseService.client.auth.currentUser!.id;
  await SupabaseService.client
      .from('users_metadata')
      .update({'onboarding_completed': true}).eq('id', uid);
}
