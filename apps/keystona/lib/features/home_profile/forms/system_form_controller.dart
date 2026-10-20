import 'package:flutter/widgets.dart';

import '../../../core/theme/aurora_home_b.dart';
import '../models/scan_prefill.dart';
import '../models/system.dart';
import '../models/system_reading.dart';
import '../models/system_template.dart';
import 'form_photo.dart';
import 'scan_reading.dart';

/// The state of the Add / Edit system form: every field, what the scan filled
/// in, validation, and the row to save. Plain Dart over text controllers, so it
/// is tested without any screen.
///
/// Create mode starts from nothing, a [SystemTemplate] (category and name from
/// a suggestion chip) or a [ScanPrefill]. Edit mode starts from [existing].
class SystemFormController extends ChangeNotifier {
  SystemFormController({
    this.existing,
    ScanPrefill? prefill,
    SystemTemplate? template,
  }) : scan = prefill == null
           ? ScanFields.none
           : ScanFields.fromResult(prefill.result),
       labelPhoto = prefill?.photo != null
           ? FormPhoto(file: prefill!.photo, isLabel: true)
           : null,
       _scanReplacementCost = prefill?.result.estimatedReplacementCostUsd {
    final s = existing;
    final r = prefill?.result;
    category = s?.category ?? template?.category ?? _scanCategory(r?.category);
    status = s?.status ?? ItemStatus.active;
    name = TextEditingController(
      text: s?.name ?? r?.name ?? template?.label ?? '',
    );
    brand = TextEditingController(text: s?.brand ?? scan.brand ?? '');
    model = TextEditingController(text: s?.modelNumber ?? scan.model ?? '');
    serial = TextEditingController(text: s?.serialNumber ?? scan.serial ?? '');
    location = TextEditingController(text: s?.location ?? '');
    installer = TextEditingController(text: s?.installer ?? '');
    price = TextEditingController(text: _money(s?.purchasePrice));
    warrantyProvider = TextEditingController(text: s?.warrantyProvider ?? '');
    notes = TextEditingController(text: s?.notes ?? '');
    final specs = s?.specifications ?? const <String, dynamic>{};
    fuel = TextEditingController(text: '${specs[specFuel] ?? ''}');
    output = TextEditingController(text: '${specs[specOutput] ?? ''}');
    filter = TextEditingController(text: '${specs[specFilter] ?? ''}');
    _specs = {...specs};

    final installed = s?.installedOn;
    month = installed?.month ?? scan.month;
    year = installed?.year ?? scan.year;
    _initialMonth = month;
    _initialYear = year;

    final existingLife = s?.reading().lifeYears;
    life = existingLife ?? r?.estimatedLifespanYears ?? _defaultLife();
    life = life
        .clamp(
          AuroraHomeBSizes.sliderMin.toInt(),
          AuroraHomeBSizes.sliderMax.toInt(),
        )
        .toInt();
    warrantyExpiration = s?.warrantyEndsOn;
    warrantyDocId = s?.linkedWarrantyDocId;

    for (final c in _textControllers) {
      c.addListener(notifyListeners);
    }
  }

  /// Specification keys stored in `systems.specifications`.
  static const String specFuel = 'fuel';
  static const String specOutput = 'output';
  static const String specFilter = 'filter';

  /// The system being edited, null when adding.
  final HomeSystem? existing;

  /// What the scan read (none when typed by hand).
  final ScanFields scan;

  /// The scanned label photo, uploaded after Save as the LABEL photo.
  final FormPhoto? labelPhoto;
  final int? _scanReplacementCost;

  bool get isEditing => existing != null;

  // Text fields.
  late final TextEditingController name;
  late final TextEditingController brand;
  late final TextEditingController model;
  late final TextEditingController serial;
  late final TextEditingController location;
  late final TextEditingController installer;
  late final TextEditingController price;
  late final TextEditingController warrantyProvider;
  late final TextEditingController notes;
  late final TextEditingController fuel;
  late final TextEditingController output;
  late final TextEditingController filter;
  late final Map<String, dynamic> _specs;

  List<TextEditingController> get _textControllers => [
    name,
    brand,
    model,
    serial,
    location,
    installer,
    price,
    warrantyProvider,
    notes,
    fuel,
    output,
    filter,
  ];

  // Choices.
  late SystemCategory category;
  late ItemStatus status;
  int? month;
  int? year;
  late int life;
  bool lifeTouched = false;
  bool addTasks = true;
  DateTime? warrantyExpiration;
  String? warrantyDocId;
  String? warrantyDocName;

  /// Photos added by hand (not the label).
  final List<FormPhoto> addedPhotos = [];

  late final int? _initialMonth;
  late final int? _initialYear;

  static SystemCategory _scanCategory(String? value) =>
      value == null ? SystemCategory.hvac : SystemCategory.fromValue(value);

  int _defaultLife() => SystemDefaults.lifespanYears(category);

  static String _money(double? v) => v == null
      ? ''
      : (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2));

  // ── Derived ───────────────────────────────────────────────────────────────

  /// Photos in display order: the label first.
  List<FormPhoto> get photos => [?labelPhoto, ...addedPhotos];

  /// A name is the only required field.
  bool get canSave => name.text.trim().isNotEmpty;

  /// The year the system should be replaced, null without an install year.
  int? get replaceYear => year == null ? null : year! + life;

  /// A scanned field stays "from scan" until its value differs.
  bool brandFromScan() => _same(brand.text, scan.brand);
  bool modelFromScan() => _same(model.text, scan.model);
  bool serialFromScan() => _same(serial.text, scan.serial);
  bool monthFromScan() => scan.month != null && month == scan.month;
  bool yearFromScan() => scan.year != null && year == scan.year;

  static bool _same(String text, String? scanned) =>
      scanned != null && text.trim() == scanned;

  /// The price, or null when empty or not a number.
  double? get priceValue =>
      double.tryParse(price.text.trim().replaceAll(',', ''));

  /// An error for the price field, null when fine.
  bool get priceInvalid {
    final t = price.text.trim();
    if (t.isEmpty) return false;
    final v = priceValue;
    return v == null || v < 0;
  }

  // ── Changes ───────────────────────────────────────────────────────────────

  /// Picking a category restarts the lifespan at its typical value, unless the
  /// person already set one by hand.
  void setCategory(SystemCategory value) {
    if (value == category) return;
    category = value;
    if (!lifeTouched) life = _defaultLife();
    notifyListeners();
  }

  void setMonth(int? value) {
    month = value;
    notifyListeners();
  }

  void setYear(int? value) {
    year = value;
    notifyListeners();
  }

  void setLife(int value) {
    life = value;
    lifeTouched = true;
    notifyListeners();
  }

  void setAddTasks(bool value) {
    addTasks = value;
    notifyListeners();
  }

  void setStatus(ItemStatus value) {
    status = value;
    notifyListeners();
  }

  void setWarrantyExpiration(DateTime? value) {
    warrantyExpiration = value;
    notifyListeners();
  }

  void setWarrantyDoc(String? id, String? docName) {
    warrantyDocId = id;
    warrantyDocName = docName;
    notifyListeners();
  }

  void addPhoto(FormPhoto photo) {
    addedPhotos.add(photo);
    notifyListeners();
  }

  void removePhoto(FormPhoto photo) {
    addedPhotos.remove(photo);
    notifyListeners();
  }

  // ── The row ───────────────────────────────────────────────────────────────

  /// `YYYY-MM-01` for the chosen month and year (January when only a year is
  /// set), the original date when neither changed, null when there is none.
  String? installationDateColumn() {
    final y = year;
    if (y == null) return null;
    if (isEditing && y == _initialYear && month == _initialMonth) {
      return existing!.installationDate;
    }
    final m = (month ?? 1).toString().padLeft(2, '0');
    return '$y-$m-01';
  }

  String _text(TextEditingController c) => c.text.trim();

  String? _orNull(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  Map<String, dynamic> _specifications() {
    final out = {..._specs};
    void put(String key, TextEditingController c) {
      final t = c.text.trim();
      if (t.isEmpty) {
        out.remove(key);
      } else {
        out[key] = t;
      }
    }

    put(specFuel, fuel);
    put(specOutput, output);
    put(specFilter, filter);
    return out;
  }

  /// The columns to write. Create omits what is empty; edit writes every
  /// editable column so cleared fields are cleared. `property_id` and
  /// `user_id` are added by the repository.
  Map<String, dynamic> toRow() {
    final date = installationDateColumn();
    if (!isEditing) {
      return {
        'category': category.value,
        'system_type': _text(name),
        'name': _text(name),
        'status': ItemStatus.active.value,
        if (_orNull(brand) != null) 'brand': _text(brand),
        if (_orNull(model) != null) 'model': _text(model),
        if (_orNull(serial) != null) 'serial_number': _text(serial),
        'installation_date': ?date,
        'expected_lifespan_min': life,
        'expected_lifespan_max': life,
        if (lifeTouched) 'lifespan_override': life,
        'estimated_replacement_cost': ?_scanReplacementCost,
      };
    }
    final specs = _specifications();
    return {
      'category': category.value,
      'name': _text(name),
      'status': status.value,
      'brand': _orNull(brand),
      'model': _orNull(model),
      'serial_number': _orNull(serial),
      'installation_date': date,
      if (lifeTouched) 'lifespan_override': life,
      'location': _orNull(location),
      'installer': _orNull(installer),
      'purchase_price': priceValue,
      'warranty_provider': _orNull(warrantyProvider),
      'warranty_expiration': warrantyExpiration == null
          ? null
          : _dateColumn(warrantyExpiration!),
      'linked_warranty_doc_id': warrantyDocId,
      'notes': _orNull(notes),
      'specifications': specs,
    };
  }

  static String _dateColumn(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    for (final c in _textControllers) {
      c.removeListener(notifyListeners);
      c.dispose();
    }
    super.dispose();
  }
}
