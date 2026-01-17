import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/system_result.dart';
import '../providers/system_providers.dart';

class SystemPhotoPicker extends ConsumerStatefulWidget {
  final String? photoUrl;
  final Function(String?) onPhotoSelected;
  final String? systemId;

  const SystemPhotoPicker({
    super.key,
    this.photoUrl,
    required this.onPhotoSelected,
    this.systemId,
  });

  @override
  ConsumerState<SystemPhotoPicker> createState() => _SystemPhotoPickerState();
}

class _SystemPhotoPickerState extends ConsumerState<SystemPhotoPicker> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Photo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (widget.photoUrl != null)
              _buildExistingPhoto()
            else
              _buildEmptyState(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploading ? null : () => _pickPhoto(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploading ? null : () => _pickPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choose Photo'),
                  ),
                ),
              ],
            ),
            if (widget.photoUrl != null)
              TextButton.icon(
                onPressed: _isUploading ? null : _removePhoto,
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text(
                  'Remove Photo',
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingPhoto() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: widget.photoUrl!,
        memCacheHeight: 400,
        memCacheWidth: 600,
        placeholder: (context, url) => Container(
          height: 200,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          height: 200,
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.error, size: 48),
          ),
        ),
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No photo added',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      await _uploadPhoto(image.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadPhoto(String filePath) async {
    if (widget.systemId == null) {
      // If no system ID yet, just store the file path for later upload
      widget.onPhotoSelected(filePath);
      return;
    }

    setState(() => _isUploading = true);

    final service = ref.read(systemServiceProvider);
    final result = await service.uploadSystemPhoto(widget.systemId!, filePath);

    if (!mounted) return;

    setState(() => _isUploading = false);

    switch (result) {
      case SystemSuccess(:final data):
        widget.onPhotoSelected(data);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded successfully')),
        );
      case SystemFailure(:final error):
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  void _removePhoto() {
    widget.onPhotoSelected(null);
  }
}
