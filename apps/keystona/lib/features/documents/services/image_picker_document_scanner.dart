import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import 'document_scanner.dart';

/// The scanner the app ships with today: the system camera through
/// `image_picker`.
///
/// It cannot detect edges, show a live preview or control the flash; those
/// arrive with a real scanner package behind the same [DocumentScanner]
/// interface.
class ImagePickerDocumentScanner implements DocumentScanner {
  ImagePickerDocumentScanner({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// JPEG quality of a captured page.
  static const int _pageQuality = 85;

  @override
  bool get detectsEdges => false;

  @override
  Stream<ScanEdgeStatus> get edgeStatus => const Stream.empty();

  @override
  Widget? buildPreview(BuildContext context) => null;

  @override
  Future<File?> capturePage({required bool flash}) async {
    final shot = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: _pageQuality,
    );
    return shot == null ? null : File(shot.path);
  }
}
