import '../models/appliance.dart';
import 'lifespan_reading.dart';

/// How an [Appliance] reads against its expected life: it ages from the
/// purchase date, and its life is the override, else the middle of the
/// expected range.
extension ApplianceLifespan on Appliance {
  /// Age, life and band. Unknown without a purchase date.
  LifespanReading lifespanReading({DateTime? now}) => LifespanReading.from(
    start: DateTime.tryParse(purchaseDate ?? ''),
    min: expectedLifespanMin,
    max: expectedLifespanMax,
    override: lifespanOverride,
    now: now,
  );
}

/// Typical lives, used when a new appliance has none from the label scan.
abstract final class ApplianceLifespanDefaults {
  /// Years by a word in the appliance's name. The first match wins.
  static const List<(String, int)> _byName = [
    ('dishwasher', 10),
    ('refrigerator', 13),
    ('fridge', 13),
    ('freezer', 15),
    ('range', 15),
    ('oven', 15),
    ('stove', 15),
    ('cooktop', 15),
    ('microwave', 9),
    ('disposal', 12),
    ('washer', 11),
    ('dryer', 13),
    ('softener', 15),
    ('air conditioner', 15),
    ('dehumidifier', 8),
    ('humidifier', 8),
    ('vacuum', 8),
    ('mower', 10),
    ('generator', 20),
  ];

  static const Map<ApplianceCategory, int> _byCategory = {
    ApplianceCategory.kitchen: 12,
    ApplianceCategory.laundry: 12,
    ApplianceCategory.climate: 12,
    ApplianceCategory.cleaning: 8,
    ApplianceCategory.outdoor: 10,
    ApplianceCategory.bathroom: 10,
    ApplianceCategory.other: 10,
  };

  /// The typical life in years for [name] in [category].
  static int years(String name, ApplianceCategory category) {
    final lower = name.toLowerCase();
    for (final (word, years) in _byName) {
      if (lower.contains(word)) return years;
    }
    return _byCategory[category] ?? _byCategory[ApplianceCategory.other]!;
  }
}
