import '../models/home_item.dart';

/// Reads the systems and appliances of a property for the Home profile
/// overview and lifespan screens (only the columns they need).
abstract interface class HomeItemsRepository {
  /// Systems and appliances that are still in service, not soft-deleted.
  Future<List<HomeItem>> fetchItems(String propertyId);
}
