import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hometrack_mobile/features/home_profile/models/property.dart';
import 'package:hometrack_mobile/features/home_profile/models/property_result.dart';
import 'package:hometrack_mobile/features/home_profile/providers/property_providers.dart';
import 'package:hometrack_mobile/features/home_profile/screens/property_setup_screen.dart';
import 'package:hometrack_mobile/features/home_profile/widgets/property_photo_picker.dart';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  final Property property;

  const PropertyDetailScreen({
    super.key,
    required this.property,
  });

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  late Property _currentProperty;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _currentProperty = widget.property;
  }

  Future<void> _handleEdit() async {
    final result = await Navigator.of(context).push<Property>(
      MaterialPageRoute(
        builder: (context) =>
            PropertySetupScreen(existingProperty: _currentProperty),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _currentProperty = result;
      });
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property?'),
        content: const Text(
          'Are you sure you want to delete this property? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    final propertyService = ref.read(propertyServiceProvider);
    final result = await propertyService.deleteProperty(_currentProperty.id);

    if (!mounted) return;

    setState(() => _isDeleting = false);

    switch (result) {
      case PropertySuccess():
        ref.read(refreshPropertiesProvider)();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Property deleted successfully')),
        );
        Navigator.of(context).pop();

      case PropertyFailure(:final error):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
    }
  }

  Future<void> _handlePhotoUpdate(String photoUrl) async {
    setState(() {
      _currentProperty = _currentProperty.copyWith(
        propertyPhotoUrl: photoUrl,
      );
    });

    // Refresh the properties list
    ref.read(refreshPropertiesProvider)();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _handleEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isDeleting ? null : _handleDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Property photo
            PropertyPhotoPicker(
              propertyId: _currentProperty.id,
              currentPhotoUrl: _currentProperty.propertyPhotoUrl,
              onPhotoUploaded: _handlePhotoUpdate,
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Address section
                  Text(
                    'Address',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    context,
                    Icons.home_outlined,
                    _currentProperty.address,
                  ),
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    context,
                    Icons.location_city_outlined,
                    '${_currentProperty.city}, ${_currentProperty.state} ${_currentProperty.zipCode}',
                  ),
                  const SizedBox(height: 24),

                  // Property details section
                  if (_hasPropertyDetails()) ...[
                    Text(
                      'Property Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_currentProperty.propertyType != null)
                      _buildInfoRow(
                        context,
                        Icons.villa_outlined,
                        _currentProperty.propertyType!.displayName,
                      ),
                    if (_currentProperty.squareFootage != null)
                      _buildInfoRow(
                        context,
                        Icons.square_foot_outlined,
                        '${_currentProperty.squareFootage} sq ft',
                      ),
                    if (_currentProperty.yearBuilt != null)
                      _buildInfoRow(
                        context,
                        Icons.calendar_today_outlined,
                        'Built in ${_currentProperty.yearBuilt}',
                      ),
                    if (_currentProperty.bedrooms != null)
                      _buildInfoRow(
                        context,
                        Icons.bed_outlined,
                        '${_currentProperty.bedrooms} bedrooms',
                      ),
                    if (_currentProperty.bathrooms != null)
                      _buildInfoRow(
                        context,
                        Icons.bathroom_outlined,
                        '${_currentProperty.bathrooms} bathrooms',
                      ),
                    if (_currentProperty.lotSize != null)
                      _buildInfoRow(
                        context,
                        Icons.landscape_outlined,
                        '${_currentProperty.lotSize} acres',
                      ),
                    const SizedBox(height: 24),
                  ],

                  // Timestamps
                  Text(
                    'Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    context,
                    Icons.access_time,
                    'Created ${_formatDate(_currentProperty.createdAt)}',
                  ),
                  _buildInfoRow(
                    context,
                    Icons.update,
                    'Updated ${_formatDate(_currentProperty.updatedAt)}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasPropertyDetails() {
    return _currentProperty.propertyType != null ||
        _currentProperty.squareFootage != null ||
        _currentProperty.yearBuilt != null ||
        _currentProperty.bedrooms != null ||
        _currentProperty.bathrooms != null ||
        _currentProperty.lotSize != null;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'just now';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor()}y ago';
    }
  }
}
