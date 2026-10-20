import '../lifespan/home_lifespan_data.dart';
import 'home_item.dart';
import 'property.dart';

/// The property, its systems and appliances, and the signed cover photo URL.
/// Assembled in `HomeProfileNotifier`, never persisted. Item mutations
/// elsewhere invalidate the provider, which refreshes everything here.
class HomeProfileOverview {
  HomeProfileOverview({
    required this.property,
    this.items = const [],
    this.exteriorPhotoSignedUrl,
  });

  final Property property;

  /// Systems and appliances in service.
  final List<HomeItem> items;

  /// Null when there is no cover photo or it could not be signed.
  final String? exteriorPhotoSignedUrl;

  /// Items ordered by life used, with the five-year forecast. Built once.
  late final HomeLifespanData lifespan = HomeLifespanData.from(items);

  int get systemCount => items.where((i) => i.isSystem).length;
  int get applianceCount => items.where((i) => !i.isSystem).length;
}
