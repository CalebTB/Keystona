import 'appliance.dart';
import 'appliance_specs.dart';
import 'form_date.dart';

/// What the Add / Edit appliance form holds, read from its controllers when
/// the person saves. Pure Dart: validation and the database columns live
/// here, so they are tested without Flutter.
class ApplianceFormData {
  const ApplianceFormData({
    required this.category,
    required this.name,
    this.brand = '',
    this.model = '',
    this.serial = '',
    this.color = '',
    this.price = '',
    this.retailer = '',
    this.purchaseDate = '',
    this.hasWarranty = false,
    this.warrantyProvider = '',
    this.warrantyExpires = '',
    this.linkedWarrantyDocId,
    this.specs = const ApplianceSpecs(),
    this.location = '',
    this.status = ItemStatus.active,
    this.lifespan = '',
    this.notes = '',
  });

  final ApplianceCategory category;
  final String name;
  final String brand;
  final String model;
  final String serial;
  final String color;
  final String price;
  final String retailer;
  final String purchaseDate;
  final bool hasWarranty;
  final String warrantyProvider;
  final String warrantyExpires;
  final String? linkedWarrantyDocId;
  final ApplianceSpecs specs;
  final String location;
  final ItemStatus status;

  /// Expected life in years, typed in "More details" (edit mode).
  final String lifespan;
  final String notes;

  /// The name is the one required field.
  bool get canSave => name.trim().isNotEmpty;

  /// Price as dollars: "$1,299.50" and "1299.5" both read; null when empty
  /// or not a number.
  static double? parsePrice(String input) {
    final cleaned = input.replaceAll(RegExp(r'[\s$,]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  static String? _text(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  /// The database columns. [existing] is the appliance being edited: its
  /// other specifications are kept. A new appliance gets the expected life
  /// range [defaultLifespanYears] (min and max), an edited one keeps its own.
  Map<String, dynamic> toFields({
    Appliance? existing,
    int? defaultLifespanYears,
  }) {
    final bought = FormDate.parse(purchaseDate);
    final ends = hasWarranty ? FormDate.parse(warrantyExpires) : null;
    final spec = specs.mergeInto(existing?.specifications);
    return {
      'category': category.value,
      'appliance_type': category.value,
      'name': name.trim(),
      'status': status.value,
      'brand': _text(brand),
      'model': _text(model),
      'serial_number': _text(serial),
      'color': _text(color),
      'retailer': _text(retailer),
      'location': _text(location),
      'notes': _text(notes),
      'purchase_price': parsePrice(price),
      'purchase_date': bought == null ? null : FormDate.column(bought),
      'warranty_provider': hasWarranty ? _text(warrantyProvider) : null,
      'warranty_expiration': ends == null ? null : FormDate.column(ends),
      'linked_warranty_doc_id': hasWarranty ? linkedWarrantyDocId : null,
      'specifications': spec,
      if (existing != null) 'lifespan_override': int.tryParse(lifespan.trim()),
      if (existing == null && defaultLifespanYears != null) ...{
        'expected_lifespan_min': defaultLifespanYears,
        'expected_lifespan_max': defaultLifespanYears,
      },
    };
  }
}
