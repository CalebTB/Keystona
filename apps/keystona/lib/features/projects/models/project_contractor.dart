import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_contractor.freezed.dart';
part 'project_contractor.g.dart';

/// A contractor linked to a project via the `project_contractors` join table.
///
/// The underlying contact lives in `emergency_contacts` — this model carries
/// join-table fields (role, contract_amount, amount_paid, rating, review_notes)
/// alongside denormalized contact display fields for the list.
@freezed
abstract class ProjectContractor with _$ProjectContractor {
  const factory ProjectContractor({
    required String id,
    required String projectId,
    required String contactId,
    required String userId,
    // Denormalized contact fields for display.
    required String contactName,
    String? contactPhone,
    String? contactEmail,
    // Join-table specific fields.
    String? role,
    double? contractAmount,
    double? amountPaid,
    int? rating,
    String? reviewNotes,
    required DateTime createdAt,
  }) = _ProjectContractor;

  factory ProjectContractor.fromJson(Map<String, dynamic> json) =>
      _$ProjectContractorFromJson(json);
}

// ── Contractor role helpers ────────────────────────────────────────────────

abstract final class ContractorRoles {
  static const all = [
    'general_contractor',
    'plumber',
    'electrician',
    'hvac',
    'painter',
    'landscaper',
    'roofer',
    'flooring',
    'tiler',
    'carpenter',
    'designer',
    'architect',
    'other',
  ];

  static String labelFor(String value) => switch (value) {
        'general_contractor' => 'General Contractor',
        'plumber' => 'Plumber',
        'electrician' => 'Electrician',
        'hvac' => 'HVAC',
        'painter' => 'Painter',
        'landscaper' => 'Landscaper',
        'roofer' => 'Roofer',
        'flooring' => 'Flooring',
        'tiler' => 'Tiler',
        'carpenter' => 'Carpenter',
        'designer' => 'Designer',
        'architect' => 'Architect',
        'other' => 'Other',
        _ => value,
      };
}
