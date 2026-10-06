import '../models/onboarding_models.dart';

/// Turns typed text into an address suggestion. Pure Dart.
///
/// PLACEHOLDER: there is no address-autocomplete source yet, so a suggestion
/// appears once the text reads "street, city, ST 12345". A real autocomplete
/// provider must replace [AddressParser.suggest] (and can add public-record
/// year built and square feet).
abstract final class AddressParser {
  /// Fewest characters before a suggestion is attempted.
  static const int minChars = 3;

  static final RegExp _pattern = RegExp(
    r'^\s*(.+?)\s*,\s*([A-Za-z .\x27-]+?)\s*,?\s+([A-Za-z]{2})\s+(\d{5})(?:-\d{4})?\s*$',
  );

  /// Suggestions for [text]. Empty when nothing matches yet.
  static List<OnbAddress> suggest(String text) {
    if (text.trim().length < minChars) return const [];
    final m = _pattern.firstMatch(text);
    if (m == null) return const [];
    return [
      OnbAddress(
        street: m.group(1)!.trim(),
        city: m.group(2)!.trim(),
        state: m.group(3)!.toUpperCase(),
        zip: m.group(4)!,
      ),
    ];
  }
}
