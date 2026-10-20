import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/home_item.dart';
import '../models/home_profile_overview.dart';
import '../models/property_edits.dart';
import 'home_repositories.dart';

part 'home_profile_provider.g.dart';

/// The user's property with its items and cover photo URL.
///
/// Kept alive so the Home tab, Settings and the Home profile screens share one
/// load. Systems and appliances providers invalidate it after any change.
/// It is cached per app session and re-read after a save.
@riverpod
class HomeProfileNotifier extends _$HomeProfileNotifier {
  @override
  Future<HomeProfileOverview> build() {
    ref.keepAlive();
    // Per-user data: rebuild (and drop the cache) when the session changes.
    if (!ref.watch(isAuthenticatedProvider)) {
      return Future.error(const NoPropertyException());
    }
    return _fetch();
  }

  Future<HomeProfileOverview> _fetch() async {
    final properties = ref.read(propertyRepositoryProvider);
    final property = await properties.fetchProperty();
    if (property == null) throw const NoPropertyException();
    final path = property.exteriorPhotoPath;
    final results = await Future.wait<Object?>([
      ref.read(homeItemsRepositoryProvider).fetchItems(property.id),
      if (path != null) properties.signedPhotoUrl(path),
    ]);
    return HomeProfileOverview(
      property: property,
      items: results[0] as List<HomeItem>,
      exteriorPhotoSignedUrl: path == null ? null : results[1] as String?,
    );
  }

  /// Writes the edits and re-reads the overview. Throws when the save fails;
  /// the cached overview stays as it was.
  Future<void> saveEdits(PropertyEdits edits) async {
    final current = state.value;
    if (current == null) throw const NoPropertyException();
    await ref.read(propertyRepositoryProvider).save(
      current.property.id,
      edits,
    );
    ref.invalidateSelf();
    await future;
  }
}

/// Thrown when the user has no property row yet.
class NoPropertyException implements Exception {
  const NoPropertyException();
}
