import 'package:intl/intl.dart';

/// Currency formatting helpers for Keystona.
///
/// Always use this class for displaying monetary values — never format
/// currency inline. All values are treated as USD.
abstract final class CurrencyFormatter {
  static final _fullFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: r'$',
  );

  static final _noDecimalFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: r'$',
    decimalDigits: 0,
  );

  /// Formats [amount] as a full USD currency string.
  ///
  /// Example: `1234.56` → `"$1,234.56"`
  static String format(num amount) => _fullFormatter.format(amount);

  /// Formats [amount] in compact form with at most one decimal place.
  ///
  /// Examples:
  /// - `1234` → `"$1.2K"`
  /// - `1234567` → `"$1.2M"`
  /// - `999` → `"$999"`
  static String formatCompact(num amount) {
    final value = amount.toDouble();
    if (value.abs() >= 1000000) {
      final millions = value / 1000000;
      return '\$${_compactDecimal(millions)}M';
    }
    if (value.abs() >= 1000) {
      final thousands = value / 1000;
      return '\$${_compactDecimal(thousands)}K';
    }
    return '\$${value.toStringAsFixed(0)}';
  }

  /// Formats [amount] as USD without decimal places.
  ///
  /// Example: `1234.56` → `"$1,234"`
  static String formatNoDecimals(num amount) =>
      _noDecimalFormatter.format(amount);

  static String _compactDecimal(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}
