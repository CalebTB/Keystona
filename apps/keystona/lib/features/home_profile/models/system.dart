// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'system.freezed.dart';
part 'system.g.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

/// Maps exactly to the Postgres `system_category` enum.
@JsonEnum(valueField: 'value')
enum SystemCategory {
  hvac('hvac'),
  plumbing('plumbing'),
  electrical('electrical'),
  roofing('roofing'),
  foundation('foundation'),
  siding('siding'),
  windowsDoors('windows_doors'),
  insulation('insulation'),
  garage('garage'),
  other('other');

  const SystemCategory(this.value);
  final String value;

  /// Human-readable display label for use in forms and cards.
  String get label => switch (this) {
        SystemCategory.hvac => 'HVAC',
        SystemCategory.plumbing => 'Plumbing',
        SystemCategory.electrical => 'Electrical',
        SystemCategory.roofing => 'Roofing',
        SystemCategory.foundation => 'Foundation',
        SystemCategory.siding => 'Siding',
        SystemCategory.windowsDoors => 'Windows & Doors',
        SystemCategory.insulation => 'Insulation',
        SystemCategory.garage => 'Garage',
        SystemCategory.other => 'Other',
      };
}

/// Maps exactly to the Postgres `item_status` enum shared with Appliances.
@JsonEnum(valueField: 'value')
enum ItemStatus {
  active('active'),
  needsRepair('needs_repair'),
  replaced('replaced'),
  removed('removed');

  const ItemStatus(this.value);
  final String value;

  /// Human-readable display label for use in forms and detail screens.
  String get label => switch (this) {
        ItemStatus.active => 'Active',
        ItemStatus.needsRepair => 'Needs Repair',
        ItemStatus.replaced => 'Replaced',
        ItemStatus.removed => 'Removed',
      };
}

// ── Model ─────────────────────────────────────────────────────────────────────

/// A major home system tracked in the Home Profile.
///
/// Maps to the `systems` table. DATE columns (installation_date,
/// warranty_expiration) are stored as `String?` because Supabase returns
/// "YYYY-MM-DD" strings for DATE columns, not full DateTime objects.
///
/// The `model` DB column is mapped to [modelNumber] via @JsonKey to avoid
/// a conflict with the Freezed-generated `_$SystemMixin.model` getter.
///
/// Fields annotated with [#N] indicate downstream usage by future issues.
@freezed
abstract class HomeSystem with _$HomeSystem {
  const factory HomeSystem({
    /// Primary key.
    required String id,

    /// FK to the user's property.
    required String propertyId,

    /// FK to the authenticated user.
    required String userId,

    // ── Classification ────────────────────────────────────────────────────────

    /// System category (HVAC, plumbing, etc.).
    required SystemCategory category,

    /// Specific system type, e.g., 'furnace_gas', 'central_ac'.
    required String systemType,

    /// User-facing display name, e.g., 'Main Furnace'.
    required String name,

    /// Current operational status.
    @Default(ItemStatus.active) ItemStatus status,

    // ── Identification ────────────────────────────────────────────────────────

    /// Manufacturer brand, e.g., 'Carrier', 'Rheem'.
    String? brand,

    /// Model number from the unit label.
    ///
    /// Stored in the `model` DB column. Renamed here to avoid a conflict
    /// with the Freezed mixin's generated `model` getter.
    @JsonKey(name: 'model') String? modelNumber,

    /// Serial number from the unit label.
    String? serialNumber,

    // ── Installation / Purchase ───────────────────────────────────────────────

    /// Installation date as "YYYY-MM-DD" string (DATE column from Supabase).
    ///
    /// [#48] Lifespan Tracking uses this as the lifespan calculation start.
    /// field_rename: snake maps `installationDate` → `installation_date`.
    String? installationDate,

    /// Purchase price paid for the system.
    double? purchasePrice,

    /// Company or person that installed the system.
    String? installer,

    // ── Location ──────────────────────────────────────────────────────────────

    /// Where in the house the system lives, e.g., 'Basement', 'Attic'.
    String? location,

    // ── Lifespan ──────────────────────────────────────────────────────────────

    /// Minimum expected lifespan in years (NAHB data).
    ///
    /// [#48] Lifespan Tracking uses this for the lifespan gauge.
    int? expectedLifespanMin,

    /// Maximum expected lifespan in years.
    ///
    /// [#48] Lifespan Tracking uses this for the lifespan gauge.
    int? expectedLifespanMax,

    /// User-supplied lifespan override in years.
    ///
    /// [#48] When present, overrides the min/max average.
    int? lifespanOverride,

    // ── Warranty ──────────────────────────────────────────────────────────────

    /// Warranty expiration as "YYYY-MM-DD" string (DATE column from Supabase).
    /// field_rename: snake maps `warrantyExpiration` → `warranty_expiration`.
    String? warrantyExpiration,

    /// Warranty provider name.
    String? warrantyProvider,

    // ── Replacement ──────────────────────────────────────────────────────────

    /// Estimated replacement cost.
    ///
    /// [#48] Lifespan Tracking shows this in the cost summary.
    double? estimatedReplacementCost,

    // ── Notes ─────────────────────────────────────────────────────────────────

    /// Freeform notes about the system.
    String? notes,

    // ── Audit ─────────────────────────────────────────────────────────────────

    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _HomeSystem;

  factory HomeSystem.fromJson(Map<String, dynamic> json) =>
      _$HomeSystemFromJson(json);
}
