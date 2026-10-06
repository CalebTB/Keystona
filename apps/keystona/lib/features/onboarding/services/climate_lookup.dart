import '../models/onboarding_models.dart';

/// Finds a [ClimateProfile] from a ZIP and state. Pure Dart, no network.
///
/// PLACEHOLDER DATA: zones come from a per-state table (the zone covering most
/// of each state) with a few ZIP-prefix overrides. A real source (county-level
/// IECC data) must replace [ClimateLookup.forZip] before launch. Reminder copy
/// beyond the kit's 4A example is draft copy for design review.
abstract final class ClimateLookup {
  /// ZIP code length.
  static const int zipLength = 5;

  /// Length of the ZIP prefix used for overrides.
  static const int _prefixLength = 3;

  /// Returns null when the ZIP or state is not recognised.
  static ClimateProfile? forZip(String zip, String state) {
    if (!RegExp(r'^\d{5}$').hasMatch(zip)) return null;
    final key = zip.substring(0, _prefixLength);
    final zm = _prefixOverrides[key] ?? _byState[state.toUpperCase()];
    if (zm == null) return null;
    return _profile(zm.$1, zm.$2);
  }

  /// ZIP prefix -> (zone, moisture). Kit example: 35758 is zone 4A.
  static const Map<String, (int, String)> _prefixOverrides = {
    '357': (4, 'A'),
    '358': (4, 'A'),
  };

  /// State -> (zone, moisture) for most of the state.
  static const Map<String, (int, String)> _byState = {
    'AL': (3, 'A'), 'AK': (7, 'A'), 'AZ': (3, 'B'), 'AR': (3, 'A'),
    'CA': (3, 'C'), 'CO': (5, 'B'), 'CT': (5, 'A'), 'DE': (4, 'A'),
    'DC': (4, 'A'), 'FL': (2, 'A'), 'GA': (3, 'A'), 'HI': (1, 'A'),
    'ID': (5, 'B'), 'IL': (5, 'A'), 'IN': (5, 'A'), 'IA': (5, 'A'),
    'KS': (4, 'A'), 'KY': (4, 'A'), 'LA': (2, 'A'), 'ME': (6, 'A'),
    'MD': (4, 'A'), 'MA': (5, 'A'), 'MI': (5, 'A'), 'MN': (6, 'A'),
    'MS': (3, 'A'), 'MO': (4, 'A'), 'MT': (6, 'B'), 'NE': (5, 'A'),
    'NV': (3, 'B'), 'NH': (6, 'A'), 'NJ': (4, 'A'), 'NM': (4, 'B'),
    'NY': (5, 'A'), 'NC': (3, 'A'), 'ND': (7, 'A'), 'OH': (5, 'A'),
    'OK': (3, 'A'), 'OR': (4, 'C'), 'PA': (5, 'A'), 'RI': (5, 'A'),
    'SC': (3, 'A'), 'SD': (6, 'A'), 'TN': (4, 'A'), 'TX': (3, 'A'),
    'UT': (5, 'B'), 'VT': (6, 'A'), 'VA': (4, 'A'), 'WA': (5, 'C'),
    'WV': (5, 'A'), 'WI': (6, 'A'), 'WY': (6, 'B'),
  };

  static ClimateProfile _profile(int zone, String moisture) {
    final band = _bands[zone] ?? _bands[7]!;
    final humidity = switch (moisture) {
      'A' => 'humid',
      'B' => 'dry',
      _ => 'marine',
    };
    final label = moisture == 'C' ? 'marine' : '${band.name}-$humidity';
    final reminders = zone == 4 && moisture == 'A' ? _mixedHumid : band.reminders;
    return ClimateProfile(
      zone: zone,
      moisture: moisture,
      label: label,
      description: band.description,
      reminders: reminders,
    );
  }

  static const List<ClimateReminder> _mixedHumid = [
    ClimateReminder('Drain outdoor faucets', 'Every Nov', ClimateGlyph.freeze),
    ClimateReminder(
      'Service the AC before summer',
      'Every Apr',
      ClimateGlyph.heat,
    ),
    ClimateReminder(
      'Check the crawlspace for moisture',
      'Twice a year',
      ClimateGlyph.moisture,
    ),
  ];

  static const Map<int, _Band> _bands = {
    1: _hot,
    2: _hot,
    3: _warm,
    4: _mixed,
    5: _cool,
    6: _cold,
    7: _veryCold,
  };

  static const _Band _hot = _Band(
    'hot',
    'Heat most of the year, and storms that can arrive fast.',
    [
      ClimateReminder('Service the AC before summer', 'Every Mar', ClimateGlyph.heat),
      ClimateReminder('Check the roof after storm season', 'Every Nov', ClimateGlyph.storm),
      ClimateReminder('Check for moisture under the house', 'Twice a year', ClimateGlyph.moisture),
    ],
  );

  static const _Band _warm = _Band(
    'warm',
    'Hot summers, mild winters, and the odd hard freeze.',
    [
      ClimateReminder('Service the AC before summer', 'Every Apr', ClimateGlyph.heat),
      ClimateReminder('Check the roof after storm season', 'Every Oct', ClimateGlyph.storm),
      ClimateReminder('Insulate exposed outdoor pipes', 'Every Nov', ClimateGlyph.freeze),
    ],
  );

  static const _Band _mixed = _Band(
    'mixed',
    'A few nights cold enough to freeze pipes, and long, humid summers that work your AC hard.',
    _mixedHumid,
  );

  static const _Band _cool = _Band(
    'cool',
    'Cold winters and warm summers, with plenty of freeze and thaw.',
    [
      ClimateReminder('Drain outdoor faucets', 'Every Oct', ClimateGlyph.freeze),
      ClimateReminder('Clean the gutters', 'Twice a year', ClimateGlyph.storm),
      ClimateReminder('Service the furnace', 'Every Sep', ClimateGlyph.heat),
    ],
  );

  static const _Band _cold = _Band(
    'cold',
    'Long, hard winters that test your heating, pipes and roof.',
    [
      ClimateReminder('Drain outdoor faucets', 'Every Oct', ClimateGlyph.freeze),
      ClimateReminder('Service the furnace', 'Every Sep', ClimateGlyph.heat),
      ClimateReminder('Check the attic for ice dam risk', 'Every Nov', ClimateGlyph.moisture),
    ],
  );

  static const _Band _veryCold = _Band(
    'very cold',
    'Deep cold for months at a time, so heating and frozen pipes come first.',
    [
      ClimateReminder('Drain outdoor faucets', 'Every Sep', ClimateGlyph.freeze),
      ClimateReminder('Service the furnace', 'Every Sep', ClimateGlyph.heat),
      ClimateReminder('Check pipe insulation', 'Every Oct', ClimateGlyph.moisture),
    ],
  );
}

class _Band {
  const _Band(this.name, this.description, this.reminders);

  final String name;
  final String description;
  final List<ClimateReminder> reminders;
}
