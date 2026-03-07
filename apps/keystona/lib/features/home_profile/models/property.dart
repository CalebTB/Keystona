import 'package:freezed_annotation/freezed_annotation.dart';

part 'property.freezed.dart';
part 'property.g.dart';

// ── Property type display ──────────────────────────────────────────────────────

extension PropertyTypeLabel on String {
  String get propertyTypeLabel => switch (this) {
        'single_family' => 'Single Family',
        'condo' => 'Condo',
        'townhouse' => 'Townhouse',
        'multi_family' => 'Multi-Family',
        'mobile' => 'Mobile Home',
        _ => this,
      };
}

// ── Model ──────────────────────────────────────────────────────────────────────

/// The user's property record from the `properties` table.
///
/// MVP: one property per user. All downstream home-profile features
/// (Systems, Appliances, Lifespan) start from [id] and [climateZone].
@freezed
abstract class Property with _$Property {
  const factory Property({
    /// [#41] Primary key — used for filtering all sub-feature queries.
    required String id,

    /// [#41] Owner FK.
    required String userId,

    // ── Address ──────────────────────────────────────────────────────────────

    /// [#41] Street address, line 1.
    required String addressLine1,

    /// [#41] Apt / unit / suite — nullable.
    String? addressLine2,

    /// [#41] City.
    required String city,

    /// [#41] Two-letter state abbreviation.
    required String state,

    /// [#41] ZIP code.
    required String zipCode,

    // ── Property details ─────────────────────────────────────────────────────

    /// [#41] Property type (single_family, condo, townhouse, multi_family, mobile).
    required String propertyType,

    /// [#41] Year the property was built.
    int? yearBuilt,

    /// [#41] Heated square footage.
    int? squareFeet,

    /// [#41] Bedrooms (supports half-baths style: 3.0, 4.0).
    double? bedrooms,

    /// [#41] Bathrooms (supports half-baths: 2.5).
    double? bathrooms,

    // ── Climate ──────────────────────────────────────────────────────────────

    /// [#43] IECC climate zone 1–8. Used to generate season-appropriate
    /// maintenance tasks after a system is added.
    int? climateZone,

    // ── Photo ────────────────────────────────────────────────────────────────

    /// [#41] Storage path for the exterior cover photo.
    String? exteriorPhotoPath,

    // ── Audit ────────────────────────────────────────────────────────────────

    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Property;

  factory Property.fromJson(Map<String, dynamic> json) =>
      _$PropertyFromJson(json);
}
