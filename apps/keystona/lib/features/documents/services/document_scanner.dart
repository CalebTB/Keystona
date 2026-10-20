import 'dart:io';

import 'package:flutter/widgets.dart';

/// Live edge status reported by a scanner that can see the page.
enum ScanEdgeStatus { searching, found }

/// Captures document pages for the camera screen.
///
/// The screen only talks to this interface, so a scanner that detects edges
/// live (and paints its own preview) can replace [ImagePickerDocumentScanner]
/// without touching any UI.
abstract interface class DocumentScanner {
  /// True when this scanner finds page edges while the user lines up the page.
  bool get detectsEdges;

  /// Edge status while lining up a page. Empty when [detectsEdges] is false.
  Stream<ScanEdgeStatus> get edgeStatus;

  /// Live camera preview painted behind the frame guides, or null when the
  /// scanner hands over to the system camera on capture.
  Widget? buildPreview(BuildContext context);

  /// Captures one page. Returns null when the user backs out.
  Future<File?> capturePage({required bool flash});
}
