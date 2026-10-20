/// Dates typed into a form as month / day / year ("12/09/2023",
/// "12 09 2023", "12092023") and the `"YYYY-MM-DD"` text a DATE column takes.
abstract final class FormDate {
  /// Earliest year accepted.
  static const int firstYear = 1900;

  /// How many years past today an expiry may be.
  static const int maxYearsAhead = 50;

  static final RegExp _separated = RegExp(r'^(\d{1,2})\D+(\d{1,2})\D+(\d{4})$');
  static final RegExp _digits = RegExp(r'^(\d{2})(\d{2})(\d{4})$');

  /// The date in [input], or null when it is empty or not a real date.
  static DateTime? parse(String input, {DateTime? now}) {
    final text = input.trim();
    final match = _separated.firstMatch(text) ?? _digits.firstMatch(text);
    if (match == null) return null;
    final month = int.parse(match.group(1)!);
    final day = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    final latest = (now ?? DateTime.now()).year + maxYearsAhead;
    if (year < firstYear || year > latest) return null;
    final date = DateTime(year, month, day);
    if (date.month != month || date.day != day) return null;
    return date;
  }

  /// True when [input] is empty or a real date.
  static bool isValidOrEmpty(String input, {DateTime? now}) =>
      input.trim().isEmpty || parse(input, now: now) != null;

  /// "12/09/2023", for a field that already holds a date.
  static String format(DateTime date) =>
      '${_two(date.month)}/${_two(date.day)}/${date.year}';

  /// "2023-12-09", what a DATE column takes.
  static String column(DateTime date) =>
      '${date.year}-${_two(date.month)}-${_two(date.day)}';

  static String _two(int n) => n.toString().padLeft(2, '0');
}
