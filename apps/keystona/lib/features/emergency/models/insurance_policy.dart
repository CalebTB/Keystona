import 'package:freezed_annotation/freezed_annotation.dart';

part 'insurance_policy.freezed.dart';
part 'insurance_policy.g.dart';

/// An insurance policy record.
///
/// Detail view + mutation implemented by [#47 Insurance Quick Reference].
@freezed
abstract class InsurancePolicy with _$InsurancePolicy {
  const factory InsurancePolicy({
    required String id,
    required String propertyId,
    required String userId,

    /// One of: homeowners, flood, earthquake, umbrella, home_warranty
    required String policyType,
    required String carrier,
    String? policyNumber,

    // ── Coverage ─────────────────────────────────────────────────────────────
    /// [#47] Total coverage amount in dollars.
    double? coverageAmount,
    /// [#47] Deductible amount in dollars.
    double? deductible,
    /// [#47] Annual premium amount in dollars.
    double? premiumAnnual,

    // ── Agent ─────────────────────────────────────────────────────────────────
    /// [#47] Agent full name.
    String? agentName,
    /// [#47] Agent direct phone — tap-to-call in #47.
    String? agentPhone,
    /// [#47] Agent email.
    String? agentEmail,

    // ── Claims ────────────────────────────────────────────────────────────────
    /// [#47] Claims hotline — tap-to-call in #47.
    String? claimsPhone,

    // ── Dates ─────────────────────────────────────────────────────────────────
    /// [#47] Policy effective date.
    DateTime? effectiveDate,
    /// [#47] Policy expiration date — shown as warning when < 30 days out.
    DateTime? expirationDate,

    // ── Linked document ───────────────────────────────────────────────────────
    /// [#47] FK to documents.id — user picks the policy PDF from Document Vault.
    String? linkedDocumentId,

    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _InsurancePolicy;

  factory InsurancePolicy.fromJson(Map<String, dynamic> json) =>
      _$InsurancePolicyFromJson(json);
}

/// Display label for [InsurancePolicy.policyType].
extension PolicyTypeLabel on String {
  String get policyTypeLabel => switch (this) {
        'homeowners' => 'Homeowners',
        'flood' => 'Flood',
        'earthquake' => 'Earthquake',
        'umbrella' => 'Umbrella',
        'home_warranty' => 'Home Warranty',
        _ => this,
      };
}
