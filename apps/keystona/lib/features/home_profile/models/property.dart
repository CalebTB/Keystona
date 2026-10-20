import 'package:freezed_annotation/freezed_annotation.dart';

part 'property.freezed.dart';
part 'property.g.dart';

/// The user's property record from the `properties` table (columns the app
/// reads). One property per user. Home profile screens start from [id].
@freezed
abstract class Property with _$Property {
  const factory Property({
    required String id,
    required String userId,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String zipCode,

    /// Stored kind: single_family, townhouse, condo, mobile or multi_family.
    /// The column is nullable.
    String? propertyType,
    int? yearBuilt,
    int? squareFeet,

    /// Lot size in square feet (shown in acres).
    int? lotSizeSqft,
    int? bedrooms,
    double? bathrooms,
    int? stories,
    @Default(false) bool hasBasement,

    /// Garage kind, free text in the column ("attached", "detached", ...).
    String? garageType,
    int? garageSpaces,
    DateTime? purchaseDate,
    double? purchasePrice,

    /// IECC climate zone 1 to 7.
    int? climateZone,

    /// Storage path of the cover photo in the `property-photos` bucket.
    String? exteriorPhotoPath,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Property;

  factory Property.fromJson(Map<String, dynamic> json) =>
      _$PropertyFromJson(json);
}
