import 'package:freezed_annotation/freezed_annotation.dart';

part 'emergency_contact.freezed.dart';
part 'emergency_contact.g.dart';

/// An emergency / contractor contact.
///
/// This is the **shared contractor pool** — contacts added in Emergency Hub
/// also appear in Projects (#5.5 Project Contractors) via a join table.
///
/// Mutation + list screen implemented by [#46 Emergency Contacts].
@freezed
abstract class EmergencyContact with _$EmergencyContact {
  const factory EmergencyContact({
    required String id,
    required String propertyId,
    required String userId,

    required String name,

    /// [#46, #5.5] Company / business name.
    String? companyName,

    /// Category enum string — one of:
    /// plumber, electrician, hvac, roofer, structural_engineer,
    /// general_contractor, fire_dept, police, gas_company, water_company, other
    required String category,

    required String phonePrimary,

    /// [#46] Secondary phone (mobile, after-hours, etc.)
    String? phoneSecondary,

    /// [#46] Email address.
    String? email,

    /// [#46] Human-readable hours (e.g. 'M–F 8am–5pm').
    String? availableHours,

    required bool is24x7,
    required bool isFavorite,

    /// [#46] Free-form notes about this contact.
    String? notes,

    /// [#46] Incremented each time user taps call — used for smart sorting.
    @Default(0) int timesUsed,

    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _EmergencyContact;

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      _$EmergencyContactFromJson(json);
}

/// Display label for [EmergencyContact.category].
extension ContactCategoryLabel on String {
  String get categoryLabel => switch (this) {
        'plumber' => 'Plumber',
        'electrician' => 'Electrician',
        'hvac' => 'HVAC',
        'roofer' => 'Roofer',
        'structural_engineer' => 'Structural Engineer',
        'general_contractor' => 'General Contractor',
        'fire_dept' => 'Fire Dept',
        'police' => 'Police',
        'gas_company' => 'Gas Company',
        'water_company' => 'Water Company',
        _ => 'Other',
      };
}
