import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/photo_picker.dart';
import '../providers/document_upload_provider.dart';

/// Adaptive bottom sheet for choosing a document source.
///
/// On iOS: [CupertinoActionSheet]. On Android: Material [ListTile] sheet.
/// After the user picks a file, calls
/// [DocumentUploadNotifier.setFile] and invokes [onFilePicked].
abstract final class UploadSourceSheet {
  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required VoidCallback onFilePicked,
  }) async {
    if (Platform.isIOS) {
      await _showCupertinoSheet(context, ref, onFilePicked: onFilePicked);
    } else {
      await _showMaterialSheet(context, ref, onFilePicked: onFilePicked);
    }
  }

  static Future<void> _showCupertinoSheet(
    BuildContext context,
    WidgetRef ref, {
    required VoidCallback onFilePicked,
  }) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Add Document'),
        message: const Text('Choose a source'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await _pickImage(context, ref, ImageSource.camera,
                  onFilePicked: onFilePicked);
            },
            child: const Text('Camera'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await _pickImage(context, ref, ImageSource.gallery,
                  onFilePicked: onFilePicked);
            },
            child: const Text('Photo Library'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await _pickFile(ref, onFilePicked: onFilePicked);
            },
            child: const Text('Files (PDF)'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  static Future<void> _showMaterialSheet(
    BuildContext context,
    WidgetRef ref, {
    required VoidCallback onFilePicked,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      builder: (sheetContext) => _MaterialSourceSheet(
        onCamera: () async {
          Navigator.of(sheetContext).pop();
          await _pickImage(context, ref, ImageSource.camera,
              onFilePicked: onFilePicked);
        },
        onGallery: () async {
          Navigator.of(sheetContext).pop();
          await _pickImage(context, ref, ImageSource.gallery,
              onFilePicked: onFilePicked);
        },
        onFiles: () async {
          Navigator.of(sheetContext).pop();
          await _pickFile(ref, onFilePicked: onFilePicked);
        },
      ),
    );
  }

  // ── Pickers ──────────────────────────────────────────────────────────────

  static Future<void> _pickImage(
    BuildContext context,
    WidgetRef ref,
    ImageSource source, {
    required VoidCallback onFilePicked,
  }) async {
    final file = source == ImageSource.camera
        ? await PhotoPicker.pickFromCamera()
        : await PhotoPicker.pickFromGallery();

    if (file == null) return;

    final mime = _mimeFromPath(file.path);
    final name = _nameFromPath(file.path);
    ref
        .read(documentUploadProvider.notifier)
        .setFile(file, mime, name);
    onFilePicked();
  }

  static Future<void> _pickFile(
    WidgetRef ref, {
    required VoidCallback onFilePicked,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );

    final path = result?.files.firstOrNull?.path;
    if (path == null) return;

    final file = File(path);
    ref
        .read(documentUploadProvider.notifier)
        .setFile(file, 'application/pdf', _nameFromPath(path));
    onFilePicked();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _mimeFromPath(String path) {
    final ext = path.split('.').lastOrNull?.toLowerCase() ?? '';
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'heic':
      case 'heif':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  static String _nameFromPath(String path) {
    final fileName = path.split('/').last;
    final dotIndex = fileName.lastIndexOf('.');
    return dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
  }
}

/// Material source selection sheet for Android.
class _MaterialSourceSheet extends StatelessWidget {
  const _MaterialSourceSheet({
    required this.onCamera,
    required this.onGallery,
    required this.onFiles,
  });

  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onFiles;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.lg,
        AppSizes.md,
        AppSizes.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add Document',
            style: AppTextStyles.h3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.md),
          _Tile(
            icon: Icons.camera_alt_outlined,
            label: 'Camera',
            onTap: onCamera,
          ),
          const Divider(height: 1),
          _Tile(
            icon: Icons.photo_library_outlined,
            label: 'Photo Library',
            onTap: onGallery,
          ),
          const Divider(height: 1),
          _Tile(
            icon: Icons.picture_as_pdf_outlined,
            label: 'Files (PDF)',
            onTap: onFiles,
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.deepNavy),
      title: Text(label, style: AppTextStyles.bodyLarge),
      onTap: onTap,
    );
  }
}

/// Re-exported so callers don't need an image_picker import.
enum ImageSource { camera, gallery }
