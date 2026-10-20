import 'package:image_picker/image_picker.dart';

import '../../../services/label_scanner_service.dart';
import 'appliance.dart';
import 'item_ref.dart';
import 'system.dart';

/// Whether a label scan is for a system or an appliance.
typedef ScanKind = ItemKind;

/// What the scan flow hands to the Add forms: the read label and the photo of
/// it (saved as the item's LABEL photo on Save).
class ScanPrefill {
  const ScanPrefill({
    required this.kind,
    required this.result,
    required this.photo,
  });

  final ScanKind kind;
  final LabelScanResult result;
  final XFile photo;
}

/// The typed `extra` of the Add routes: the item being edited (none when
/// adding) and an optional scan to prefill from.
///
/// NOTE: the legacy model classes [HomeSystem] and [Appliance] are imported
/// read-only; the tracks that replace them keep these two class names or
/// update this file's imports.
class ItemFormArgs {
  const ItemFormArgs({
    this.existingSystem,
    this.existingAppliance,
    this.prefill,
  });

  final HomeSystem? existingSystem;
  final Appliance? existingAppliance;
  final ScanPrefill? prefill;
}
