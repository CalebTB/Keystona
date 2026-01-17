import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hometrack_mobile/features/home_profile/models/property_result.dart';
import 'package:hometrack_mobile/features/home_profile/providers/property_providers.dart';

class PropertyPhotoPicker extends ConsumerStatefulWidget {
  final String propertyId;
  final String? currentPhotoUrl;
  final void Function(String photoUrl)? onPhotoUploaded;

  const PropertyPhotoPicker({
    super.key,
    required this.propertyId,
    this.currentPhotoUrl,
    this.onPhotoUploaded,
  });

  @override
  ConsumerState<PropertyPhotoPicker> createState() =>
      _PropertyPhotoPickerState();
}

class _PropertyPhotoPickerState extends ConsumerState<PropertyPhotoPicker> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  File? _pendingImage;
  String? _uploadedPhotoUrl;

  @override
  void initState() {
    super.initState();
    _uploadedPhotoUrl = widget.currentPhotoUrl;
  }

  @override
  void didUpdateWidget(PropertyPhotoPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local state if parent passes a new URL
    if (widget.currentPhotoUrl != oldWidget.currentPhotoUrl) {
      _uploadedPhotoUrl = widget.currentPhotoUrl;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _pendingImage = File(image.path);
        _isUploading = true;
      });

      final propertyService = ref.read(propertyServiceProvider);
      final result = await propertyService.uploadPropertyPhoto(
        propertyId: widget.propertyId,
        filePath: image.path,
      );

      if (!mounted) return;

      setState(() {
        _isUploading = false;
        _pendingImage = null;
      });

      switch (result) {
        case PropertySuccess(:final data):
          setState(() {
            _uploadedPhotoUrl = data;
          });
          widget.onPhotoUploaded?.call(data);

        case PropertyFailure(:final error):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.message)),
          );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploading = false;
        _pendingImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _showImageSourceDialog() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_uploadedPhotoUrl != null && _uploadedPhotoUrl!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _removePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _removePhoto() async {
    // For MVP, we don't actually delete from storage, just update the URL to null
    // This is acceptable since storage cleanup can be handled later
    setState(() {
      _uploadedPhotoUrl = null;
    });
    widget.onPhotoUploaded?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Display current photo, pending image, or placeholder
          if (_pendingImage != null)
            Image.file(
              _pendingImage!,
              fit: BoxFit.cover,
            )
          else if (_uploadedPhotoUrl != null &&
              _uploadedPhotoUrl!.isNotEmpty)
            Image.network(
              _uploadedPhotoUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholder(theme);
              },
            )
          else
            _buildPlaceholder(theme),

          // Upload overlay
          if (_isUploading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Uploading photo...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

          // Camera button
          if (!_isUploading)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.small(
                onPressed: _showImageSourceDialog,
                child: const Icon(Icons.camera_alt),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'Add Property Photo',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
