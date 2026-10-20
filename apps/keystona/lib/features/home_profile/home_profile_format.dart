import 'package:intl/intl.dart';

import '../onboarding/models/onboarding_models.dart';
import '../onboarding/services/climate_lookup.dart';
import 'models/property.dart';

/// Number, money, date and climate text for the Home profile screens. Pure.
abstract final class HomeFormat {
  /// Square feet in an acre.
  static const double sqftPerAcre = 43560;

  /// Decimals shown for acres.
  static const int acreDecimals = 2;

  /// Money from this amount up is shown in thousands on the chart ("$2.6K").
  static const double thousand = 1000;

  static final NumberFormat _grouped = NumberFormat.decimalPattern('en_US');

  /// "2,140".
  static String number(num value) => _grouped.format(value);

  /// "$1,800" (whole dollars).
  static String money(num value) => '\$${number(value.round())}';

  /// "$2.6K" under a million, for the chart bars.
  static String moneyShort(num value) {
    if (value < thousand) return money(value);
    final k = (value / thousand).toStringAsFixed(1);
    return '\$${k.endsWith('.0') ? k.substring(0, k.length - 2) : k}K';
  }

  /// "Mar 2024".
  static String monthYear(DateTime date) => DateFormat('MMM y').format(date);

  /// "2.5" or "4" (no trailing zero).
  static String half(num value) =>
      value == value.truncateToDouble() ? '${value.toInt()}' : '$value';

  /// "0.31" for a lot in square feet.
  static String acres(int sqft) =>
      _trim((sqft / sqftPerAcre).toStringAsFixed(acreDecimals));

  /// Whole square feet for acres typed by hand, null when not a number.
  static int? sqftFromAcres(String text) {
    final acres = double.tryParse(text.trim());
    return acres == null || acres < 0 ? null : (acres * sqftPerAcre).round();
  }

  static String _trim(String value) {
    if (!value.contains('.')) return value;
    return value.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  /// "4A" when the stand-in lookup agrees with the stored zone, else the zone
  /// number alone. Null when no zone is stored.
  static String? zoneCode(Property property) {
    final zone = property.climateZone;
    if (zone == null) return null;
    final found = _lookup(property);
    return found != null && found.zone == zone ? found.zoneLabel : '$zone';
  }

  /// "Zone 4A · mixed-humid". Null when no zone is stored.
  static String? climateLabel(Property property) {
    final code = zoneCode(property);
    if (code == null) return null;
    final found = _lookup(property);
    final named = found != null && found.zone == property.climateZone;
    return named ? 'Zone $code · ${found.label}' : 'Zone $code';
  }

  static ClimateProfile? _lookup(Property property) =>
      ClimateLookup.forZip(property.zipCode, property.state);
}
