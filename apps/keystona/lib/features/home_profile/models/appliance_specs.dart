/// The specifications of an appliance, kept in `appliances.specifications`
/// (JSONB). Pure Dart: the form, the detail screen and the scan read the same
/// keys.
///
/// Keys not listed here are kept as they are when the form saves.
class ApplianceSpecs {
  const ApplianceSpecs({
    this.capacity,
    this.type,
    this.spinSpeed,
    this.hookup,
    this.energyStar = false,
  });

  /// Reads the JSONB map; unknown or empty values are ignored.
  factory ApplianceSpecs.fromJson(Map<String, dynamic>? json) {
    String? text(String key) {
      final value = json?[key];
      if (value is! String) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    return ApplianceSpecs(
      capacity: text(capacityKey),
      type: text(typeKey),
      spinSpeed: text(spinSpeedKey),
      hookup: text(hookupKey),
      energyStar: json?[energyStarKey] == true,
    );
  }

  /// Reads the "Label: Value" lines the scan returns in its notes.
  ///
  /// Understands capacity ("Capacity: 4.5 cu ft"), type, spin speed, hookup
  /// and Energy Star. Other lines are ignored.
  factory ApplianceSpecs.fromScanNotes(String? notes) {
    if (notes == null || notes.trim().isEmpty) return const ApplianceSpecs();
    String? capacity;
    String? type;
    String? spin;
    String? hookup;
    var energy = false;
    for (final line in notes.split('\n')) {
      final at = line.indexOf(':');
      final key = (at < 0 ? line : line.substring(0, at)).trim().toLowerCase();
      final value = at < 0 ? '' : line.substring(at + 1).trim();
      if (key.contains('energy star')) {
        energy = value.isEmpty || !_negative.hasMatch(value);
      } else if (value.isEmpty) {
        continue;
      } else if (key.contains('capacity')) {
        capacity = value;
      } else if (key.contains('spin')) {
        spin = value;
      } else if (key.contains('hookup') || key.contains('connection')) {
        hookup = value;
      } else if (key == 'type' || key.contains('configuration')) {
        type = value;
      }
    }
    return ApplianceSpecs(
      capacity: capacity,
      type: type,
      spinSpeed: spin,
      hookup: hookup,
      energyStar: energy,
    );
  }

  static final RegExp _negative = RegExp(
    r'^(no|false|not\b)',
    caseSensitive: false,
  );

  static const String capacityKey = 'capacity';
  static const String typeKey = 'type';
  static const String spinSpeedKey = 'spin_speed';
  static const String hookupKey = 'hookup';
  static const String energyStarKey = 'energy_star';

  /// Unit the form shows after the capacity number.
  static const String capacityUnit = 'cu ft';

  /// The washer types the form offers.
  static const List<String> washerTypes = [
    'Front-load',
    'Top-load',
    'Stackable',
  ];

  final String? capacity;
  final String? type;
  final String? spinSpeed;
  final String? hookup;
  final bool energyStar;

  /// How many specs there are to show.
  int get count => entries.length;

  /// Label and value pairs for the detail card, in the kit's order. Energy
  /// Star reads "Certified".
  List<({String label, String value})> get entries => [
    if (capacity != null) (label: 'Capacity', value: capacity!),
    if (type != null) (label: 'Type', value: type!),
    if (spinSpeed != null) (label: 'Spin speed', value: spinSpeed!),
    if (hookup != null) (label: 'Hookup', value: hookup!),
    if (energyStar) (label: 'Energy Star', value: 'Certified'),
  ];

  /// The capacity as the form's number field shows it: "4.5 cu ft" -> "4.5".
  String get capacityNumber {
    final c = capacity;
    if (c == null) return '';
    final match = RegExp(r'^\s*(\d+(?:[.,]\d+)?)').firstMatch(c);
    return match == null ? c : match.group(1)!;
  }

  /// The text to store for a capacity typed in the form: a bare number gets
  /// the unit, anything else is kept as typed.
  static String? capacityFromInput(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    return RegExp(r'^\d+([.,]\d+)?$').hasMatch(trimmed)
        ? '$trimmed $capacityUnit'
        : trimmed;
  }

  /// [existing] with these specs written over it. Unknown keys stay; an empty
  /// capacity, type or Energy Star removes its key.
  Map<String, dynamic> mergeInto(Map<String, dynamic>? existing) {
    final out = <String, dynamic>{...?existing};
    void put(String key, String? value) {
      if (value == null) {
        out.remove(key);
      } else {
        out[key] = value;
      }
    }

    put(capacityKey, capacity);
    put(typeKey, type);
    // The form has no fields for these two: they are written when known and
    // never removed.
    if (spinSpeed != null) out[spinSpeedKey] = spinSpeed;
    if (hookup != null) out[hookupKey] = hookup;
    if (energyStar) {
      out[energyStarKey] = true;
    } else {
      out.remove(energyStarKey);
    }
    return out;
  }

  ApplianceSpecs copyWith({
    Object? capacity = _keep,
    Object? type = _keep,
    bool? energyStar,
  }) => ApplianceSpecs(
    capacity: identical(capacity, _keep) ? this.capacity : capacity as String?,
    type: identical(type, _keep) ? this.type : type as String?,
    spinSpeed: spinSpeed,
    hookup: hookup,
    energyStar: energyStar ?? this.energyStar,
  );

  static const Object _keep = Object();
}
