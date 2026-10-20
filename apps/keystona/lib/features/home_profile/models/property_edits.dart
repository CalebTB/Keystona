import 'dart:io';

/// Everything HomeEdit writes to `properties`, plus an optional new cover
/// photo. A plain UPDATE of these columns works under RLS. Blank fields are
/// written as null so they can be cleared.
class PropertyEdits {
  const PropertyEdits({
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.hasBasement,
    this.propertyType,
    this.yearBuilt,
    this.squareFeet,
    this.lotSizeSqft,
    this.bedrooms,
    this.bathrooms,
    this.stories,
    this.garageType,
    this.garageSpaces,
    this.purchaseDate,
    this.purchasePrice,
    this.climateZone,
    this.newPhoto,
  });

  final String addressLine1;
  final String city;
  final String state;
  final String zipCode;
  final bool hasBasement;
  final String? propertyType;
  final int? yearBuilt;
  final int? squareFeet;
  final int? lotSizeSqft;
  final int? bedrooms;
  final double? bathrooms;
  final int? stories;
  final String? garageType;
  final int? garageSpaces;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final int? climateZone;

  /// A cover photo picked in this edit. Uploaded on save.
  final File? newPhoto;

  /// Column values for the UPDATE. [photoPath] is the uploaded cover photo's
  /// path; the column is left alone when it is null.
  Map<String, dynamic> toColumns({String? photoPath}) => {
    'address_line1': addressLine1,
    'city': city,
    'state': state,
    'zip_code': zipCode,
    'property_type': propertyType,
    'year_built': yearBuilt,
    'square_feet': squareFeet,
    'lot_size_sqft': lotSizeSqft,
    'bedrooms': bedrooms,
    'bathrooms': bathrooms,
    'stories': stories,
    'has_basement': hasBasement,
    'garage_type': garageType,
    'garage_spaces': garageSpaces,
    // A DATE column wants "YYYY-MM-DD".
    'purchase_date': purchaseDate?.toIso8601String().split('T').first,
    'purchase_price': purchasePrice,
    'climate_zone': climateZone,
    'exterior_photo_path': ?photoPath,
  };
}
