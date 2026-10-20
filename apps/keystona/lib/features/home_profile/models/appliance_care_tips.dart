import 'appliance.dart';
import 'appliance_specs.dart';

/// The care sentence that closes an appliance's lifespan card, by what the
/// appliance is. Words in the name win over the category.
abstract final class ApplianceCareTips {
  static const String frontLoader =
      'Front-loaders last longest when the door is left open to dry and the '
      'drain filter stays clean.';

  static const List<(String, String)> _byName = [
    (
      'dryer',
      'Dryers last longest when the lint trap is cleared every load and the '
          'vent stays clear.',
    ),
    (
      'dishwasher',
      'Dishwashers last longest when the filter is rinsed each month and '
          'the spray arms stay clear.',
    ),
    (
      'washer',
      'Washers last longest when the load is not too big and the drain '
          'filter stays clean.',
    ),
    (
      'refrigerator',
      'Fridges last longest when the coils are vacuumed twice a year and the '
          'door seals stay tight.',
    ),
    (
      'fridge',
      'Fridges last longest when the coils are vacuumed twice a year and the '
          'door seals stay tight.',
    ),
    (
      'freezer',
      'Freezers last longest when the coils stay dust free and the door '
          'seals stay tight.',
    ),
    (
      'range',
      'Ranges last longest when spills are wiped up before they bake on.',
    ),
    (
      'oven',
      'Ovens last longest when spills are wiped up before they bake on.',
    ),
  ];

  static const String general =
      'Regular upkeep is the best way to get the most out of it.';

  static String forAppliance(Appliance appliance) {
    final name = appliance.name.toLowerCase();
    final type = ApplianceSpecs.fromJson(appliance.specifications).type;
    if (name.contains('washer') &&
        !name.contains('dish') &&
        type != null &&
        type.toLowerCase().contains('front')) {
      return frontLoader;
    }
    for (final (word, tip) in _byName) {
      if (name.contains(word)) return tip;
    }
    return general;
  }
}
