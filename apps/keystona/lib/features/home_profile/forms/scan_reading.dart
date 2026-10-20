import '../../../services/label_scanner_service.dart';

/// What a label scan gives the Add system form, as plain values: the fields
/// the form marks "from scan".
class ScanFields {
  const ScanFields({
    this.brand,
    this.model,
    this.serial,
    this.month,
    this.year,
  });

  /// Reads a scan result. The install date is the label's manufacture date
  /// (or the estimated year): not a true install date, but the closest the
  /// label offers.
  factory ScanFields.fromResult(LabelScanResult r) {
    final parts = (r.manufactureDate ?? '').split('-');
    final year = int.tryParse(parts.first) ?? r.estimatedYear;
    final month = parts.length > 1 ? int.tryParse(parts[1]) : null;
    return ScanFields(
      brand: _clean(r.brand),
      model: _clean(r.modelNumber),
      serial: _clean(r.serialNumber),
      month: month != null && month >= 1 && month <= 12 ? month : null,
      year: year,
    );
  }

  static const ScanFields none = ScanFields();

  final String? brand;
  final String? model;
  final String? serial;
  final int? month;
  final int? year;

  /// How many fields the scan filled in ("We read 5 fields from the label").
  int get count => [
    brand,
    model,
    serial,
    month,
    year,
  ].where((v) => v != null).length;

  static String? _clean(String? v) {
    final t = v?.trim();
    return t == null || t.isEmpty ? null : t;
  }
}
