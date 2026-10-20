import 'package:flutter/material.dart';

import '../../models/appliance.dart';

/// The outlined glyph on an appliance's row, by what it is called and then by
/// its category.
abstract final class ApplianceIcons {
  static const List<(String, IconData)> _byName = [
    ('dishwasher', Icons.dinner_dining_outlined),
    ('refrigerator', Icons.kitchen_outlined),
    ('fridge', Icons.kitchen_outlined),
    ('freezer', Icons.kitchen_outlined),
    ('range', Icons.microwave_outlined),
    ('oven', Icons.microwave_outlined),
    ('stove', Icons.microwave_outlined),
    ('microwave', Icons.microwave_outlined),
    ('washer', Icons.local_laundry_service_outlined),
    ('dryer', Icons.dry_cleaning_outlined),
  ];

  static const Map<ApplianceCategory, IconData> _byCategory = {
    ApplianceCategory.kitchen: Icons.kitchen_outlined,
    ApplianceCategory.laundry: Icons.local_laundry_service_outlined,
    ApplianceCategory.climate: Icons.ac_unit_outlined,
    ApplianceCategory.cleaning: Icons.cleaning_services_outlined,
    ApplianceCategory.outdoor: Icons.yard_outlined,
    ApplianceCategory.bathroom: Icons.bathtub_outlined,
    ApplianceCategory.other: Icons.devices_other_outlined,
  };

  static IconData forAppliance(Appliance appliance) =>
      forName(appliance.name, appliance.category);

  static IconData forName(String name, ApplianceCategory category) {
    final lower = name.toLowerCase();
    for (final (word, icon) in _byName) {
      if (lower.contains(word)) return icon;
    }
    return _byCategory[category] ?? Icons.devices_other_outlined;
  }
}
