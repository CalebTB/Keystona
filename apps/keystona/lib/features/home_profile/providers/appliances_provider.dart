import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../models/appliance.dart';
import '../repositories/appliances_repository.dart';
import '../repositories/supabase_appliances_repository.dart';
import 'appliance_detail_provider.dart';
import 'home_profile_provider.dart';

part 'appliances_provider.g.dart';

/// The data source behind the appliance screens. Tests override it.
final appliancesRepositoryProvider = Provider<AppliancesRepository>(
  (ref) => SupabaseAppliancesRepository(SupabaseService.client),
);

/// First line of the home's address, for the Appliances eyebrow.
final homeAddressLineProvider = FutureProvider.autoDispose<String?>(
  (ref) => ref.watch(appliancesRepositoryProvider).addressLine(),
);

/// The home's appliances, plus the changes the appliance screens make to
/// them. The list is cached across screens (the Docs link picker reads it).
///
/// A write never sets the state to loading: the list updates, the write
/// follows, and a failed write puts the list back and rethrows.
@riverpod
class AppliancesNotifier extends _$AppliancesNotifier {
  @override
  Future<List<Appliance>> build() {
    ref.keepAlive();
    return ref.read(appliancesRepositoryProvider).list();
  }

  AppliancesRepository get _repository => ref.read(appliancesRepositoryProvider);

  List<Appliance> get _items => state.value ?? const [];

  /// Refetches the list. Keeps showing the current list while it loads.
  Future<void> refresh() async {
    state = await AsyncValue.guard(_repository.list);
  }

  /// Adds an appliance and returns its id.
  Future<String> addAppliance(Map<String, dynamic> fields) async {
    final id = await _repository.add(fields);
    ref.invalidate(homeProfileProvider);
    await refresh();
    return id;
  }

  /// Writes the changed [fields] of [id] and refreshes everything that shows
  /// it.
  Future<void> updateAppliance(String id, Map<String, dynamic> fields) async {
    await _repository.update(id, fields);
    ref.invalidate(applianceDetailProvider(id));
    ref.invalidate(homeProfileProvider);
    await refresh();
  }

  /// Deletes [id]. The row leaves the list at once. Pass the same id to
  /// [restore] to undo.
  Future<void> softDelete(String id) async {
    final before = _items;
    state = AsyncData([
      for (final a in before)
        if (a.id != id) a,
    ]);
    try {
      await _repository.softDelete(id);
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
    ref.invalidate(homeProfileProvider);
  }

  /// Undo of [softDelete].
  Future<void> restore(String id) async {
    await _repository.restore(id);
    ref.invalidate(applianceDetailProvider(id));
    ref.invalidate(homeProfileProvider);
    await refresh();
  }
}
