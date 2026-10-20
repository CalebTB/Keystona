import 'appliance.dart';

/// "Often forgotten" appliances the list offers to add. Opening one fills the
/// Add form with its name and category.
class ApplianceSuggestion {
  const ApplianceSuggestion(this.name, this.category);

  final String name;
  final ApplianceCategory category;

  /// The chips under the Appliances list.
  static const List<ApplianceSuggestion> oftenForgotten = [
    ApplianceSuggestion('Microwave', ApplianceCategory.kitchen),
    ApplianceSuggestion('Garbage disposal', ApplianceCategory.kitchen),
    ApplianceSuggestion('Water softener', ApplianceCategory.other),
    ApplianceSuggestion('Freezer', ApplianceCategory.kitchen),
  ];
}
