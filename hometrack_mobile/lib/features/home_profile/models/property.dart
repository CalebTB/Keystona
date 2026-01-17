/// Property model for home information
///
/// Represents a single property/home with address, details, and optional photo.
/// Uses simple Dart class pattern (no freezed) consistent with auth MVP.
class Property {
  final String id;
  final String userId;
  final String address;
  final String city;
  final String state; // 2-char US state
  final String zipCode; // 5 or 9 digits
  final int? squareFootage;
  final int? yearBuilt;
  final int? bedrooms;
  final double? bathrooms;
  final double? lotSize;
  final PropertyType? propertyType;
  final String? climateZone; // Nullable, not populated in MVP
  final String? propertyPhotoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Property({
    required this.id,
    required this.userId,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    this.squareFootage,
    this.yearBuilt,
    this.bedrooms,
    this.bathrooms,
    this.lotSize,
    this.propertyType,
    this.climateZone,
    this.propertyPhotoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Property from JSON (Supabase response)
  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zipCode: json['zip_code'] as String,
      squareFootage: json['square_footage'] as int?,
      yearBuilt: json['year_built'] as int?,
      bedrooms: json['bedrooms'] as int?,
      bathrooms: (json['bathrooms'] as num?)?.toDouble(),
      lotSize: (json['lot_size'] as num?)?.toDouble(),
      propertyType: json['property_type'] != null
          ? PropertyType.fromString(json['property_type'] as String)
          : null,
      climateZone: json['climate_zone'] as String?,
      propertyPhotoUrl: json['property_photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert Property to JSON for Supabase insert/update
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'square_footage': squareFootage,
      'year_built': yearBuilt,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'lot_size': lotSize,
      'property_type': propertyType?.toDbValue(),
      'climate_zone': climateZone,
      'property_photo_url': propertyPhotoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Property copyWith({
    String? id,
    String? userId,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    int? squareFootage,
    int? yearBuilt,
    int? bedrooms,
    double? bathrooms,
    double? lotSize,
    PropertyType? propertyType,
    String? climateZone,
    String? propertyPhotoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Property(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      squareFootage: squareFootage ?? this.squareFootage,
      yearBuilt: yearBuilt ?? this.yearBuilt,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      lotSize: lotSize ?? this.lotSize,
      propertyType: propertyType ?? this.propertyType,
      climateZone: climateZone ?? this.climateZone,
      propertyPhotoUrl: propertyPhotoUrl ?? this.propertyPhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Property type enum with database value mapping
///
/// Maps Dart enum values to snake_case database values to prevent
/// serialization bugs. Returns null instead of throwing on unknown values
/// for forward compatibility.
enum PropertyType {
  singleFamily,
  condo,
  townhouse,
  multiFamily,
  mobileHome,
  other;

  /// Convert enum to database value (snake_case)
  String toDbValue() {
    switch (this) {
      case PropertyType.singleFamily:
        return 'single_family';
      case PropertyType.condo:
        return 'condo';
      case PropertyType.townhouse:
        return 'townhouse';
      case PropertyType.multiFamily:
        return 'multi_family';
      case PropertyType.mobileHome:
        return 'mobile_home';
      case PropertyType.other:
        return 'other';
    }
  }

  /// Convert database value to enum
  ///
  /// Returns null for unknown values instead of throwing to handle
  /// forward compatibility if new property types are added to the database.
  static PropertyType? fromString(String? value) {
    if (value == null) return null;

    switch (value) {
      case 'single_family':
        return PropertyType.singleFamily;
      case 'condo':
        return PropertyType.condo;
      case 'townhouse':
        return PropertyType.townhouse;
      case 'multi_family':
        return PropertyType.multiFamily;
      case 'mobile_home':
        return PropertyType.mobileHome;
      case 'other':
        return PropertyType.other;
      default:
        return null; // Gracefully handle unknown types
    }
  }

  /// Human-readable display name for UI
  String get displayName {
    switch (this) {
      case PropertyType.singleFamily:
        return 'Single Family Home';
      case PropertyType.condo:
        return 'Condominium';
      case PropertyType.townhouse:
        return 'Townhouse';
      case PropertyType.multiFamily:
        return 'Multi-Family';
      case PropertyType.mobileHome:
        return 'Mobile Home';
      case PropertyType.other:
        return 'Other';
    }
  }
}
