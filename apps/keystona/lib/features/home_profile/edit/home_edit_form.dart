import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../onboarding/services/climate_lookup.dart';
import '../home_edit_copy.dart';
import '../home_profile_format.dart';
import '../models/property.dart';
import '../models/property_edits.dart';

/// The state, validation and output of the HomeEdit form. Pure Dart apart from
/// the text controllers it owns; [dispose] frees them.
///
/// It listens to its controllers, so a widget can rebuild from it with a
/// `ListenableBuilder`. Nullable steppers stay null until touched, so saving
/// never writes a value the person did not choose.
class HomeEditForm extends ChangeNotifier {
  HomeEditForm(this.initial, {DateTime? now})
    : _now = now ?? DateTime.now(),
      street = TextEditingController(text: initial.addressLine1),
      city = TextEditingController(text: initial.city),
      state = TextEditingController(text: initial.state),
      zip = TextEditingController(text: initial.zipCode),
      year = TextEditingController(text: initial.yearBuilt?.toString() ?? ''),
      sqft = TextEditingController(
        text: initial.squareFeet == null
            ? ''
            : HomeFormat.number(initial.squareFeet!),
      ),
      lot = TextEditingController(
        text: initial.lotSizeSqft == null
            ? ''
            : HomeFormat.acres(initial.lotSizeSqft!),
      ),
      price = TextEditingController(
        text: initial.purchasePrice == null
            ? ''
            : HomeFormat.number(initial.purchasePrice!.round()),
      ),
      kind = initial.propertyType,
      garageType = initial.garageType,
      garageSpaces = initial.garageSpaces,
      bedrooms = initial.bedrooms,
      bathrooms = initial.bathrooms,
      stories = initial.stories,
      hasBasement = initial.hasBasement,
      purchaseDate = initial.purchaseDate {
    _initialValues = _values();
    for (final c in _controllers) {
      c.addListener(notifyListeners);
    }
  }

  final Property initial;
  final DateTime _now;

  final TextEditingController street;
  final TextEditingController city;
  final TextEditingController state;
  final TextEditingController zip;
  final TextEditingController year;
  final TextEditingController sqft;
  final TextEditingController lot;
  final TextEditingController price;

  String? kind;
  String? garageType;
  int? garageSpaces;
  int? bedrooms;
  double? bathrooms;
  int? stories;
  bool hasBasement;
  DateTime? purchaseDate;

  /// A cover photo picked in this edit, not yet uploaded.
  File? photo;

  late final List<Object?> _initialValues;

  /// Stepper limits and steps (kit).
  static const int bedroomsMin = 0;
  static const int bedroomsMax = 9;
  static const double bathroomsMin = 1;
  static const double bathroomsMax = 8;
  static const double bathroomsStep = 0.5;
  static const int storiesMin = 1;
  static const int storiesMax = 4;
  static const int garageSpacesMin = 1;
  static const int garageSpacesMax = 6;

  /// Earliest year built accepted, exclusive (kit: 1700 < year).
  static const int earliestYear = 1700;

  static const int _yearDigits = 4;
  static const int _stateLetters = 2;

  List<TextEditingController> get _controllers => [
    street, city, state, zip, year, sqft, lot, price,
  ];

  List<Object?> _values() => [
    street.text.trim(),
    city.text.trim(),
    state.text.trim().toUpperCase(),
    zip.text.trim(),
    year.text.trim(),
    sqft.text.trim(),
    lot.text.trim(),
    price.text.trim(),
    kind,
    garageType,
    garageSpaces,
    bedrooms,
    bathrooms,
    stories,
    hasBasement,
    purchaseDate,
    photo?.path,
  ];

  /// Any field differs from what the form opened with.
  bool get dirty => !listEquals(_values(), _initialValues);

  // ── Validation ────────────────────────────────────────────────────────────

  static final RegExp _digits = RegExp(r'^\d+$');

  bool get streetOk => street.text.trim().isNotEmpty;
  bool get cityOk => city.text.trim().isNotEmpty;
  bool get stateOk => RegExp(
    r'^[A-Za-z]{' '$_stateLetters' r'}$',
  ).hasMatch(state.text.trim());
  bool get zipOk => RegExp(
    r'^\d{' '${ClimateLookup.zipLength}' r'}$',
  ).hasMatch(zip.text.trim());

  /// Blank is fine (optional); otherwise four digits in range.
  bool get yearOk {
    final text = year.text.trim();
    if (text.isEmpty) return true;
    if (!RegExp(r'^\d{' '$_yearDigits' r'}$').hasMatch(text)) return false;
    final value = int.parse(text);
    return value > earliestYear && value <= _now.year;
  }

  bool get sqftOk => _blankOr(sqft.text, (t) => _digits.hasMatch(_strip(t)));
  bool get lotOk => _blankOr(lot.text, (t) => HomeFormat.sqftFromAcres(t) != null);
  bool get priceOk => _blankOr(price.text, (t) => _digits.hasMatch(_strip(t)));

  bool get valid =>
      streetOk && cityOk && stateOk && zipOk && yearOk && sqftOk && lotOk && priceOk;

  /// Save is on when something changed and everything that changed is valid.
  bool get canSave => dirty && valid;

  static bool _blankOr(String text, bool Function(String) ok) =>
      text.trim().isEmpty || ok(text.trim());

  /// "$318,000" / "2,140" to "318000" / "2140".
  static String _strip(String text) => text.replaceAll(RegExp(r'[\s,$]'), '');

  // ── Helper lines ──────────────────────────────────────────────────────────

  String? get yearHelp {
    if (!yearOk) return HomeEditCopy.yearHelpBad;
    final text = year.text.trim();
    if (text.isNotEmpty && text != (initial.yearBuilt?.toString() ?? '')) {
      return HomeEditCopy.yearHelpChanged;
    }
    return null;
  }

  bool get zipChanged => zip.text.trim() != initial.zipCode;

  String get zipHelp => zipChanged
      ? (zipOk ? HomeEditCopy.zipHelpChanged : HomeEditCopy.zipHelpBad)
      : HomeEditCopy.zipHelpLocked;

  String? get stateHelp => stateOk ? null : HomeEditCopy.stateHelpBad;

  // ── Steppers ──────────────────────────────────────────────────────────────

  void stepBedrooms(int delta) {
    bedrooms = _step(bedrooms, delta, bedroomsMin, bedroomsMax);
    notifyListeners();
  }

  void stepBathrooms(int delta) {
    final next = _step(bathrooms, delta * bathroomsStep, bathroomsMin, bathroomsMax);
    bathrooms = next;
    notifyListeners();
  }

  void stepStories(int delta) {
    stories = _step(stories, delta, storiesMin, storiesMax);
    notifyListeners();
  }

  void stepGarageSpaces(int delta) {
    garageSpaces = _step(garageSpaces, delta, garageSpacesMin, garageSpacesMax);
    notifyListeners();
  }

  /// From null a plus lands on [min] and a minus stays null.
  static T? _step<T extends num>(T? value, num delta, T min, T max) {
    if (value == null) return delta > 0 ? min : null;
    final next = value + delta;
    if (next < min) return min;
    if (next > max) return max;
    return (value is int ? next.toInt() : next.toDouble()) as T;
  }

  // ── Setters that notify ───────────────────────────────────────────────────

  void setKind(String? value) {
    kind = value;
    notifyListeners();
  }

  void setGarage(String? type) {
    garageType = type;
    if (type == null) {
      garageSpaces = null;
    } else {
      garageSpaces ??= garageSpacesMin;
    }
    notifyListeners();
  }

  void setBasement(bool value) {
    hasBasement = value;
    notifyListeners();
  }

  void setPurchaseDate(DateTime? value) {
    purchaseDate = value;
    notifyListeners();
  }

  void setPhoto(File? value) {
    photo = value;
    notifyListeners();
  }

  // ── Output ────────────────────────────────────────────────────────────────

  /// The edits to write. Only call when [canSave]. A changed ZIP or state
  /// rechecks the climate zone with the stand-in lookup; an unknown ZIP keeps
  /// the zone it had.
  PropertyEdits toEdits() {
    final stateText = state.text.trim().toUpperCase();
    final zipText = zip.text.trim();
    final moved = zipText != initial.zipCode || stateText != initial.state;
    final zone = moved
        ? (ClimateLookup.forZip(zipText, stateText)?.zone ?? initial.climateZone)
        : initial.climateZone;
    final lotText = lot.text.trim();
    final priceText = _strip(price.text);
    final sqftText = _strip(sqft.text);
    return PropertyEdits(
      addressLine1: street.text.trim(),
      city: city.text.trim(),
      state: stateText,
      zipCode: zipText,
      hasBasement: hasBasement,
      propertyType: kind,
      yearBuilt: int.tryParse(year.text.trim()),
      squareFeet: int.tryParse(sqftText),
      // Acres are shown rounded: keep the stored square feet unless typed over.
      lotSizeSqft: lotText == _initialValues[6]
          ? initial.lotSizeSqft
          : HomeFormat.sqftFromAcres(lotText),
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      stories: stories,
      garageType: garageType,
      garageSpaces: garageSpaces,
      purchaseDate: purchaseDate,
      purchasePrice: double.tryParse(priceText),
      climateZone: zone,
      newPhoto: photo,
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.removeListener(notifyListeners);
      c.dispose();
    }
    super.dispose();
  }
}
