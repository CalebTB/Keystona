import '../lifespan/lifespan_reading.dart';
import 'system.dart';

/// A system's age against its expected life, and its dates parsed.
extension HomeSystemReading on HomeSystem {
  /// The install date, or null when none is set.
  DateTime? get installedOn =>
      installationDate == null ? null : DateTime.tryParse(installationDate!);

  /// The warranty end date, or null when none is set.
  DateTime? get warrantyEndsOn =>
      warrantyExpiration == null ? null : DateTime.tryParse(warrantyExpiration!);

  /// Age from the install date against the one expected life. Pass [now] in
  /// tests.
  LifespanReading reading({DateTime? now}) => LifespanReading.from(
    start: installedOn,
    min: expectedLifespanMin,
    max: expectedLifespanMax,
    override: lifespanOverride,
    now: now,
  );

  /// "Northline NF95-080B · Basement": brand and model, then where it is.
  /// Null when there is nothing to say.
  String? get subtitle {
    final unit = [
      brand,
      modelNumber,
    ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' ');
    final place = (location ?? '').trim();
    final parts = [if (unit.isNotEmpty) unit, if (place.isNotEmpty) place];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}
