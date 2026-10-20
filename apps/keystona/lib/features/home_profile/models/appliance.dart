import 'package:freezed_annotation/freezed_annotation.dart';

part 'appliance.freezed.dart';
part 'appliance.g.dart';

@JsonEnum(valueField: 'value')
enum ApplianceCategory {
  kitchen('kitchen'),
  laundry('laundry'),
  climate('climate'),
  cleaning('cleaning'),
  outdoor('outdoor'),
  bathroom('bathroom'),
  other('other');

  const ApplianceCategory(this.value);
  final String value;

  String get label => switch (this) {
        ApplianceCategory.kitchen => 'Kitchen',
        ApplianceCategory.laundry => 'Laundry',
        ApplianceCategory.climate => 'Climate',
        ApplianceCategory.cleaning => 'Cleaning',
        ApplianceCategory.outdoor => 'Outdoor',
        ApplianceCategory.bathroom => 'Bathroom',
        ApplianceCategory.other => 'Other',
      };
}

@JsonEnum(valueField: 'value')
enum ItemStatus {
  active('active'),
  needsRepair('needs_repair'),
  replaced('replaced'),
  removed('removed');

  const ItemStatus(this.value);
  final String value;

  String get label => switch (this) {
        ItemStatus.active => 'Active',
        ItemStatus.needsRepair => 'Needs Repair',
        ItemStatus.replaced => 'Replaced',
        ItemStatus.removed => 'Removed',
      };
}

@freezed
abstract class Appliance with _$Appliance {
  const factory Appliance({
    required String id,
    required String propertyId,
    required String userId,
    required ApplianceCategory category,
    required String name,
    @Default(ItemStatus.active) ItemStatus status,
    String? brand,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'model') String? modelNumber,
    String? serialNumber,
    String? purchaseDate,
    String? warrantyExpiration,
    double? purchasePrice,

    /// Where it was bought (`retailer`).
    String? retailer,
    String? location,
    String? color,
    int? lifespanOverride,

    /// Expected life range in years (`expected_lifespan_min` / `_max`), from
    /// the label scan or the appliance-type default.
    int? expectedLifespanMin,
    int? expectedLifespanMax,
    String? warrantyProvider,
    String? linkedWarrantyDocId,
    String? notes,
    double? estimatedReplacementCost,

    /// Type, capacity, spin speed, hookup, Energy Star (`specifications`,
    /// JSONB). Read it through `ApplianceSpecs`.
    Map<String, dynamic>? specifications,
    String? replacedByApplianceId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Appliance;

  factory Appliance.fromJson(Map<String, dynamic> json) =>
      _$ApplianceFromJson(json);
}
