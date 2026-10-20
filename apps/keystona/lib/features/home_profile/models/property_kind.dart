import '../../onboarding/models/onboarding_models.dart';

/// Labels for the stored `properties.property_type` values. The four choices
/// of the HomeEdit control are the onboarding [HomeKind]s (same stored
/// strings); `multi_family` stays readable but is not offered.
abstract final class PropertyKinds {
  /// Choices shown on HomeEdit, in kit order.
  static const List<HomeKind> choices = HomeKind.values;

  static const String multiFamily = 'multi_family';

  /// "Single-family", "Manufactured", ... Empty when unknown.
  static String labelFor(String? value) {
    final kind = HomeKind.fromValue(value);
    if (kind != null) return kind.label;
    if (value == multiFamily) return 'Multi-family';
    return '';
  }
}
