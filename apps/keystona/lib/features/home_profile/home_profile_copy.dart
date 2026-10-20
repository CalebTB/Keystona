import 'home_profile_format.dart';
import 'lifespan/lifespan_forecast.dart';
import 'lifespan/lifespan_reading.dart';
import 'models/home_item.dart';
import 'models/property.dart';
import 'models/property_kind.dart';
import 'widgets/shared/item_key_value.dart';

/// Copy for the Home profile overview. Text the kit draws is verbatim; lines
/// marked "invented" had no kit text (listed in the build report).
abstract final class HomeProfileCopy {
  static const String back = 'Home';
  static const String edit = 'Edit';
  static const String coverTag = 'FRONT OF HOUSE';
  static const String systemsAll = 'All systems';
  static const String aroundTitle = 'Around the house';
  static const String nextFive = 'NEXT 5 YEARS';
  static const String howLong = 'How long things last';
  static const String theProperty = 'THE PROPERTY';
  static const String upkeep = 'UPKEEP';
  static const String addByScan = 'Scan a label to add one';

  /// Invented.
  static const String loadError = "We couldn't load your home.";
  static const String noHomeTitle = 'No home yet';
  static const String noHomeBody =
      'Add your home to see its profile, what is in it and how long it lasts.';
  static const String noHomeAction = 'Set up your home';
  static const String nothingDueTitle = 'Nothing due';
  static const String nothingDueSub = 'in the next 5 years';
  static const String nothingDueBody =
      'Add install dates and lifespans to see when things wear out.';

  static String eyebrow(Property p) {
    final date = p.purchaseDate;
    return date == null
        ? 'YOUR HOME'
        : 'YOUR HOME · OWNED SINCE ${HomeFormat.monthYear(date).toUpperCase()}';
  }

  /// "SINGLE-FAMILY · BUILT 1998 · 2,140 SQ FT · 4 BD · 2.5 BA · ZONE 4A".
  static String facts(Property p) {
    final kind = PropertyKinds.labelFor(p.propertyType);
    final zone = HomeFormat.zoneCode(p);
    return [
      if (kind.isNotEmpty) kind,
      if (p.yearBuilt != null) 'Built ${p.yearBuilt}',
      if (p.squareFeet != null) '${HomeFormat.number(p.squareFeet!)} sq ft',
      if (p.bedrooms != null) '${p.bedrooms} bd',
      if (p.bathrooms != null) '${HomeFormat.half(p.bathrooms!)} ba',
      if (zone != null) 'Zone $zone',
    ].join(' · ').toUpperCase();
  }

  static String calloutTitle(HomeItem item) =>
      item.reading.band == LifespanBand.past
      ? '${item.name} is past its expected life'
      : '${item.name} is at the end of its life';

  /// "12 YRS OF ~12 · BUDGET ~$1,800 FOR 2027".
  static String calloutSub(HomeItem item, LifespanForecast forecast) {
    final r = item.reading;
    final cost = item.cost;
    return [
      '${r.ageLabel} of ${r.lifeLabel}',
      if (cost != null)
        'Budget ~${HomeFormat.money(cost)} for ${forecast.yearFor(item)}',
    ].join(' · ').toUpperCase();
  }

  static String systemsTitle(int count) => 'SYSTEMS · $count';
  static String agingCount(int count) => '$count AGING';
  static String appliancesPill(int count) =>
      '$count ${count == 1 ? 'appliance' : 'appliances'}';
  static String healthTitle(int score) => 'HOME HEALTH · $score';

  /// Invented: what the upkeep score is made of.
  static String upkeepMeta(int completed, int total) =>
      '$completed OF $total TASKS DONE THIS YEAR';

  /// "14 REMINDERS NOT TIED TO A SYSTEM · 2 OFF".
  static String aroundMeta(int reminders, int off) {
    final base =
        '$reminders ${reminders == 1 ? 'REMINDER' : 'REMINDERS'} '
        'NOT TIED TO A SYSTEM';
    return off > 0 ? '$base · $off OFF' : base;
  }

  /// "~$4,400" and "to replace 3 things".
  static String totalBig(LifespanForecast f) => f.total > 0
      ? '~${HomeFormat.money(f.total)}'
      : '${f.dueItems.length}';
  static String totalSub(LifespanForecast f) {
    final n = f.dueItems.length;
    return f.total > 0
        ? 'to replace $n ${n == 1 ? 'thing' : 'things'}'
        : '${n == 1 ? 'thing' : 'things'} due in the next 5 years';
  }

  /// "The water heater and dishwasher come first. Setting aside about $75 a
  /// month covers it." Invented wording around the kit's example.
  static String nextFiveBody(LifespanForecast f) {
    final first = f.years.firstWhere((y) => y.names.isNotEmpty).names;
    final names = first.length <= 2
        ? first.join(' and ')
        : '${first.take(2).join(', ')} and ${first.length - 2} more';
    final verb = first.length == 1 ? 'comes' : 'come';
    final lead = '$names $verb first.';
    return f.total > 0
        ? '$lead Setting aside about ${HomeFormat.money(f.perMonth)} a '
              'month covers it.'
        : lead;
  }

  static String chartLabel(ForecastYear y) =>
      y.amount > 0 ? HomeFormat.moneyShort(y.amount) : '—';

  /// Rows of the "THE PROPERTY" card. Only the ones with data.
  static List<ItemKeyValue> propertyRows(Property p) {
    final bought = [
      if (p.purchaseDate != null) HomeFormat.monthYear(p.purchaseDate!),
      if (p.purchasePrice != null) HomeFormat.money(p.purchasePrice!),
    ].join(' · ');
    final garage = garageLabel(p.garageType, p.garageSpaces);
    final climate = HomeFormat.climateLabel(p);
    final stories = p.stories == null
        ? null
        : p.hasBasement
        ? '${p.stories} + basement'
        : '${p.stories}';
    return [
      if (bought.isNotEmpty) ItemKeyValue(label: 'Bought', value: bought),
      if (p.lotSizeSqft != null)
        ItemKeyValue(
          label: 'Lot',
          value: '${HomeFormat.acres(p.lotSizeSqft!)} acres',
        ),
      if (stories != null) ItemKeyValue(label: 'Stories', value: stories),
      if (garage != null) ItemKeyValue(label: 'Garage', value: garage),
      if (climate != null) ItemKeyValue(label: 'Climate', value: climate),
    ];
  }

  /// "Attached · 2 cars". Null when there is no garage type.
  static String? garageLabel(String? type, int? spaces) {
    if (type == null || type.isEmpty) return null;
    final name = '${type[0].toUpperCase()}${type.substring(1)}';
    if (spaces == null) return name;
    return '$name · $spaces ${spaces == 1 ? 'car' : 'cars'}';
  }
}
