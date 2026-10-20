import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'document_upload_provider.dart';
import 'scan_reading_provider.dart';

/// Where an add-document flow starts and ends.
///
/// The form ([documentUploadProvider]) and the smart-scan reading
/// ([scanReadingProvider]) are kept alive on purpose: a file is picked in a
/// sheet before the form screen exists, and a scan can keep reading after the
/// camera closes. Anything kept alive outlives the screens, so the flow must
/// clear it at BOTH ends:
///
///  * [reset] when a flow begins (the add-from sheet), so a flow that was
///    abandoned in some way nobody anticipated cannot leak into this one;
///  * [reset] when the form is closed or saved.
///
/// This is why closing a renewal and then adding a new document used to open
/// the renewal again. Never write flow state into these providers from
/// `build()`; apply input once, from `initState`.
abstract final class DocumentFlow {
  /// Clears the form and the scan reading.
  static void reset(WidgetRef ref) {
    ref.invalidate(documentUploadProvider);
    ref.read(scanReadingProvider.notifier).reset();
  }
}
