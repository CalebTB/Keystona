import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/supabase_service.dart';
import '../models/onboarding_models.dart';
import 'address_parser.dart';
import 'climate_lookup.dart';

/// Persists [OnboardingProgress] on the device (no address, no PII).
abstract class OnboardingProgressStore {
  Future<OnboardingProgress> load(String userId);
  Future<void> save(String userId, OnboardingProgress progress);
}

/// [OnboardingProgressStore] backed by SharedPreferences, keyed by user.
class PrefsOnboardingProgressStore implements OnboardingProgressStore {
  const PrefsOnboardingProgressStore();

  static String _key(String userId) => 'onboarding_progress_v1_$userId';

  @override
  Future<OnboardingProgress> load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    if (raw == null) return const OnboardingProgress();
    return OnboardingProgress.fromJson(
      jsonDecode(raw) as Map<String, Object?>,
    );
  }

  @override
  Future<void> save(String userId, OnboardingProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(userId), jsonEncode(progress.toJson()));
  }
}

/// Remote writes and reads for onboarding.
abstract class OnboardingRepository {
  /// Creates the user's property, or updates it when one already exists.
  Future<void> saveProperty(OnbPropertyDraft draft);

  /// Marks onboarding done on the profile.
  Future<void> completeOnboarding();

  /// The user's saved home for the checklist card, or null when none.
  Future<OnbHomeSummary?> loadHomeSummary();
}

/// Supabase implementation of [OnboardingRepository].
class SupabaseOnboardingRepository implements OnboardingRepository {
  const SupabaseOnboardingRepository();

  @override
  Future<void> saveProperty(OnbPropertyDraft draft) async {
    final client = SupabaseService.client;
    final uid = client.auth.currentUser!.id;
    final payload = <String, dynamic>{
      'address_line1': draft.address.street,
      'city': draft.address.city,
      'state': draft.address.state,
      'zip_code': draft.address.zip,
      'property_type': draft.kind.value,
      'year_built': ?draft.yearBuilt,
      'square_feet': ?draft.squareFeet,
      'climate_zone': ?draft.climate?.zone,
    };
    final existing = await client
        .from('properties')
        .select('id')
        .eq('user_id', uid)
        .isFilter('deleted_at', null)
        .maybeSingle();
    if (existing == null) {
      await client.from('properties').insert({...payload, 'user_id': uid});
    } else {
      await client
          .from('properties')
          .update(payload)
          .eq('id', existing['id'] as String);
    }
  }

  @override
  Future<void> completeOnboarding() async {
    final client = SupabaseService.client;
    await client
        .from('profiles')
        .update({'onboarding_completed': true}).eq(
      'id',
      client.auth.currentUser!.id,
    );
  }

  @override
  Future<OnbHomeSummary?> loadHomeSummary() async {
    final client = SupabaseService.client;
    final row = await client
        .from('properties')
        .select('address_line1, property_type, year_built, square_feet, climate_zone')
        .eq('user_id', client.auth.currentUser!.id)
        .isFilter('deleted_at', null)
        .maybeSingle();
    if (row == null) return null;
    return OnbHomeSummary(
      street: row['address_line1'] as String,
      kind: HomeKind.fromValue(row['property_type'] as String?),
      yearBuilt: (row['year_built'] as num?)?.toInt(),
      squareFeet: (row['square_feet'] as num?)?.toInt(),
      climateZone: (row['climate_zone'] as num?)?.toInt(),
    );
  }
}

/// Address suggestions for the typed text.
abstract class AddressSource {
  Future<List<OnbAddress>> suggest(String text);
}

/// Placeholder source that parses "street, city, ST 12345".
class ParsedAddressSource implements AddressSource {
  const ParsedAddressSource();

  @override
  Future<List<OnbAddress>> suggest(String text) async =>
      AddressParser.suggest(text);
}

/// Climate for a ZIP. Returns null when the ZIP is not covered.
abstract class ClimateSource {
  Future<ClimateProfile?> lookup({required String zip, required String state});
}

/// Placeholder source backed by [ClimateLookup].
class LocalClimateSource implements ClimateSource {
  const LocalClimateSource();

  @override
  Future<ClimateProfile?> lookup({
    required String zip,
    required String state,
  }) async =>
      ClimateLookup.forZip(zip, state);
}

/// Starts the Premium trial. RevenueCat is not wired yet (mocked).
abstract class TrialStarter {
  Future<void> startTrial(OnbPlan plan);
}

/// Mock: succeeds without a purchase. Replace with the RevenueCat purchase.
class MockTrialStarter implements TrialStarter {
  const MockTrialStarter();

  @override
  Future<void> startTrial(OnbPlan plan) async {}
}
