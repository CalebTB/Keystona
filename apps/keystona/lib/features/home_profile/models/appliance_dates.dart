import 'appliance.dart';

/// The appliance's DATE columns (`"YYYY-MM-DD"`) as dates.
extension ApplianceDates on Appliance {
  /// When it was bought; null when unknown.
  DateTime? get purchasedOn => DateTime.tryParse(purchaseDate ?? '');

  /// When the warranty ends; null when there is none.
  DateTime? get warrantyEndsOn => DateTime.tryParse(warrantyExpiration ?? '');
}
