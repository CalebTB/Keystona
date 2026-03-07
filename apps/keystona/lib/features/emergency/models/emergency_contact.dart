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

    /// Category enum string — one of the [ContactCategories.all] values.
    /// DB enum: plumber, electrician, hvac_tech, general_contractor, roofer,
    /// pest_control, locksmith, insurance_agent, neighbor, other
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
///
/// Uses the exact DB enum values:
/// plumber, electrician, hvac_tech, general_contractor, roofer,
/// pest_control, locksmith, insurance_agent, neighbor, other
extension ContactCategoryLabel on String {
  String get categoryLabel => switch (this) {
        'plumber' => 'Plumber',
        'electrician' => 'Electrician',
        'hvac_tech' => 'HVAC Technician',
        'general_contractor' => 'General Contractor',
        'roofer' => 'Roofer',
        'pest_control' => 'Pest Control',
        'locksmith' => 'Locksmith',
        'insurance_agent' => 'Insurance Agent',
        'neighbor' => 'Neighbor',
        _ => 'Other',
      };
}

/// All contact category options as value + label records.
///
/// Values match the DB enum exactly. Use [ContactCategories.all] to
/// populate pickers, and [ContactCategories.labelFor] to display a label.
abstract final class ContactCategories {
  static const all = [
    (value: 'plumber', label: 'Plumber'),
    (value: 'electrician', label: 'Electrician'),
    (value: 'hvac_tech', label: 'HVAC Technician'),
    (value: 'general_contractor', label: 'General Contractor'),
    (value: 'roofer', label: 'Roofer'),
    (value: 'pest_control', label: 'Pest Control'),
    (value: 'locksmith', label: 'Locksmith'),
    (value: 'insurance_agent', label: 'Insurance Agent'),
    (value: 'neighbor', label: 'Neighbor'),
    (value: 'other', label: 'Other'),
  ];

  static String labelFor(String value) => all
      .firstWhere(
        (c) => c.value == value,
        orElse: () => (value: value, label: value),
      )
      .label;
}
