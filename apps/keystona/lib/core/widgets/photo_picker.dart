import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../theme/aurora_colors.dart';
import '../theme/aurora_typography.dart';
import '../widgets/aurora/aurora_sheet.dart';

/// Unified camera and gallery photo picker with automatic compression.
///
/// Always use this class instead of calling [ImagePicker] directly.
/// Compression is applied when the resulting file exceeds [maxSizeKb].
abstract final class PhotoPicker {
  static final _picker = ImagePicker();

  /// Opens the device gallery and returns the selected [File].
  ///
  /// Returns `null` if the user cancels. Compresses to [maxSizeKb] if needed.
  static Future<File?> pickFromGallery({int maxSizeKb = 2048}) async {
    final xFile = await _picker.pickImage(source: ImageSource.gallery);
    if (xFile == null) return null;
    return _compressIfNeeded(File(xFile.path), maxSizeKb);
  }

  /// Opens the device camera and returns the captured [File].
  ///
  /// Returns `null` if the user cancels. Compresses to [maxSizeKb] if needed.
  static Future<File?> pickFromCamera({int maxSizeKb = 2048}) async {
    final xFile = await _picker.pickImage(source: ImageSource.camera);
    if (xFile == null) return null;
    return _compressIfNeeded(File(xFile.path), maxSizeKb);
  }

  /// Shows a bottom sheet with Camera and Gallery options.
  ///
  /// Returns `null` if the user cancels without selecting.
  /// Compresses to [maxSizeKb] if the resulting file exceeds the limit.
  static Future<File?> showPicker(
    BuildContext context, {
    int maxSizeKb = 2048,
  }) async {
    File? result;

    await showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: AuroraSheet.topRadius(context),
      ),
      builder: (sheetContext) => _PhotoPickerSheet(
        onCamera: () async {
          Navigator.of(sheetContext).pop();
          result = await pickFromCamera(maxSizeKb: maxSizeKb);
        },
        onGallery: () async {
          Navigator.of(sheetContext).pop();
          result = await pickFromGallery(maxSizeKb: maxSizeKb);
        },
      ),
    );

    return result;
  }

  /// Compresses [file] so it fits within [maxSizeKb].
  ///
  /// Returns the original file unchanged when it already fits.
  static Future<File> _compressIfNeeded(File file, int maxSizeKb) async {
    final bytes = await file.length();
    if (bytes <= maxSizeKb * 1024) return file;

    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final xFile = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 80,
      minWidth: 1080,
      minHeight: 1080,
    );

    return xFile != null ? File(xFile.path) : file;
  }
}

/// Internal bottom sheet for source selection.
class _PhotoPickerSheet extends StatelessWidget {
  const _PhotoPickerSheet({
    required this.onCamera,
    required this.onGallery,
  });

  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Select photo source',
            style: AuroraType.h3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(
              Icons.camera_alt_outlined,
              color: AuroraColors.ink,
            ),
            title: Text('Camera', style: AuroraType.bodyLg),
            onTap: onCamera,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(
              Icons.photo_library_outlined,
              color: AuroraColors.ink,
            ),
            title: Text('Gallery', style: AuroraType.bodyLg),
            onTap: onGallery,
          ),
        ],
      ),
    );
  }
}
