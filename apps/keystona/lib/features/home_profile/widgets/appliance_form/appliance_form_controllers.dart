import 'package:flutter/material.dart';

import '../../models/appliance.dart';
import '../../models/appliance_specs.dart';
import '../../models/form_date.dart';

/// The text controllers of the Add / Edit appliance form, created together
/// and disposed together.
class ApplianceFormControllers {
  ApplianceFormControllers({Appliance? existing}) {
    final specs = ApplianceSpecs.fromJson(existing?.specifications);
    name.text = existing?.name ?? '';
    brand.text = existing?.brand ?? '';
    model.text = existing?.modelNumber ?? '';
    serial.text = existing?.serialNumber ?? '';
    color.text = existing?.color ?? '';
    price.text = existing?.purchasePrice == null
        ? ''
        : existing!.purchasePrice!.toStringAsFixed(
            existing.purchasePrice! % 1 == 0 ? 0 : 2,
          );
    retailer.text = existing?.retailer ?? '';
    purchaseDate.text = _date(existing?.purchaseDate);
    warrantyProvider.text = existing?.warrantyProvider ?? '';
    warrantyExpires.text = _date(existing?.warrantyExpiration);
    capacity.text = specs.capacityNumber;
    location.text = existing?.location ?? '';
    lifespan.text = existing?.lifespanOverride?.toString() ?? '';
    notes.text = existing?.notes ?? '';
  }

  final name = TextEditingController();
  final brand = TextEditingController();
  final model = TextEditingController();
  final serial = TextEditingController();
  final color = TextEditingController();
  final price = TextEditingController();
  final retailer = TextEditingController();
  final purchaseDate = TextEditingController();
  final warrantyProvider = TextEditingController();
  final warrantyExpires = TextEditingController();
  final capacity = TextEditingController();
  final location = TextEditingController();
  final lifespan = TextEditingController();
  final notes = TextEditingController();

  static String _date(String? column) {
    final d = DateTime.tryParse(column ?? '');
    return d == null ? '' : FormDate.format(d);
  }

  /// Adds [listener] to every controller (the form rebuilds as it is typed).
  void addListener(VoidCallback listener) {
    for (final c in _all) {
      c.addListener(listener);
    }
  }

  List<TextEditingController> get _all => [
    name,
    brand,
    model,
    serial,
    color,
    price,
    retailer,
    purchaseDate,
    warrantyProvider,
    warrantyExpires,
    capacity,
    location,
    lifespan,
    notes,
  ];

  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
  }
}
