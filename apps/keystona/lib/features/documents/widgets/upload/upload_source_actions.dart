import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/aurora_docs_b.dart';
import '../../../../core/widgets/photo_picker.dart';
import '../../../../core/widgets/snackbar_service.dart';
import '../../models/document_scan.dart';
import '../../providers/document_upload_provider.dart';
import '../../screens/document_camera_screen.dart';

/// What the user chose to add, once it has landed in the upload state.
///
/// Each method returns true when a file is now ready for the form.
class UploadSourceActions {
  const UploadSourceActions(this.notifier);

  /// Captured before any await: the sheet's own ref is gone by then.
  final DocumentUploadNotifier notifier;

  /// A picture from the photo library.
  Future<bool> fromLibrary(BuildContext context) async {
    final file = await PhotoPicker.pickFromGallery();
    if (file == null || !context.mounted) return false;
    return _accept(context, file, _mimeOf(file.path));
  }

  /// A PDF or image from the Files app.
  Future<bool> fromFiles(BuildContext context) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: AuroraUploadRules.fileExtensions,
    );
    final path = picked?.files.firstOrNull?.path;
    if (path == null || !context.mounted) return false;
    return _accept(context, File(path), _mimeOf(path));
  }

  /// The camera screen. [smart] opens it in smart scan mode.
  Future<bool> fromCamera(BuildContext context, {required bool smart}) async {
    final result = await Navigator.of(context, rootNavigator: true)
        .push<ScanFlowResult>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => DocumentCameraScreen(startSmart: smart),
          ),
        );
    if (result == null) return false;
    notifier.setScan(result.outcome, label: result.outcome.label);
    final found = result.found;
    if (found != null) await notifier.applyScanResult(found);
    return true;
  }

  Future<bool> _accept(BuildContext context, File file, String mime) async {
    final size = await file.length();
    if (!context.mounted) return false;
    if (size > AuroraUploadRules.maxFileBytes) {
      SnackbarService.showError(context, 'That file is over 25 MB');
      return false;
    }
    notifier.setPickedFile(
      file: file,
      mimeType: mime,
      sizeBytes: size,
      name: _nameOf(file.path),
      previewFile: mime.startsWith('image/') ? file : null,
    );
    return true;
  }

  static String _mimeOf(String path) =>
      switch (path.split('.').last.toLowerCase()) {
        'pdf' => 'application/pdf',
        'png' => 'image/png',
        'heic' || 'heif' => 'image/heic',
        _ => 'image/jpeg',
      };

  static String _nameOf(String path) {
    final fileName = path.split(Platform.pathSeparator).last;
    final dot = fileName.lastIndexOf('.');
    return dot > 0 ? fileName.substring(0, dot) : fileName;
  }
}
