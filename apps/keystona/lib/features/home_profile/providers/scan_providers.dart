import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/label_scanner_service.dart';

/// Reads a label photo through the scan-label function. Tests override it.
typedef LabelReader =
    Future<LabelScanResult> Function(XFile photo, {required bool isAppliance});

/// Takes or picks a photo. Null when the person backs out. Tests override it.
typedef PhotoSource = Future<XFile?> Function(ImageSource source);

final labelReaderProvider = Provider<LabelReader>(
  (ref) =>
      (photo, {required isAppliance}) =>
          LabelScannerService.scanImage(photo, isAppliance: isAppliance),
);

/// Longest edge (px) and JPEG quality of a photo taken for a label or an item.
const int kScanImageMaxWidth = 1600;
const int kScanImageQuality = 85;

final photoSourceProvider = Provider<PhotoSource>((ref) {
  final picker = ImagePicker();
  return (source) => picker.pickImage(
    source: source,
    maxWidth: kScanImageMaxWidth.toDouble(),
    imageQuality: kScanImageQuality,
  );
});
