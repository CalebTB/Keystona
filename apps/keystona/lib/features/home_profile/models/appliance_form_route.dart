import 'appliance.dart';
import 'appliance_suggestion.dart';
import 'scan_prefill.dart';

/// What the Add / Edit appliance route can be opened with, read from the
/// route's `extra`: the foundation's [ItemFormArgs] (an appliance to edit, a
/// scan to prefill from), a bare [Appliance], an [ApplianceSuggestion] from the
/// list's chips, or nothing.
class ApplianceFormRoute {
  const ApplianceFormRoute({this.existing, this.prefill, this.suggestion});

  factory ApplianceFormRoute.fromExtra(Object? extra) {
    if (extra is ItemFormArgs) {
      return ApplianceFormRoute(
        existing: extra.existingAppliance,
        prefill: extra.prefill,
      );
    }
    if (extra is Appliance) return ApplianceFormRoute(existing: extra);
    if (extra is ApplianceSuggestion) {
      return ApplianceFormRoute(suggestion: extra);
    }
    return const ApplianceFormRoute();
  }

  final Appliance? existing;
  final ScanPrefill? prefill;
  final ApplianceSuggestion? suggestion;
}
