import 'package:flutter/material.dart';
import 'package:hometrack_mobile/features/home_profile/models/property.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback? onTap;

  const PropertyCard({
    super.key,
    required this.property,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property photo or placeholder
            if (property.propertyPhotoUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  property.propertyPhotoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPhotoPlaceholder(theme);
                  },
                ),
              )
            else
              _buildPhotoPlaceholder(theme),

            // Property details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.address,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${property.city}, ${property.state} ${property.zipCode}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_hasOptionalDetails()) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        if (property.bedrooms != null)
                          _buildDetailChip(
                            context,
                            Icons.bed_outlined,
                            '${property.bedrooms} bed',
                          ),
                        if (property.bathrooms != null)
                          _buildDetailChip(
                            context,
                            Icons.bathroom_outlined,
                            '${property.bathrooms} bath',
                          ),
                        if (property.squareFootage != null)
                          _buildDetailChip(
                            context,
                            Icons.square_foot_outlined,
                            '${property.squareFootage} sq ft',
                          ),
                        if (property.propertyType != null)
                          _buildDetailChip(
                            context,
                            Icons.home_outlined,
                            property.propertyType!.displayName,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder(ThemeData theme) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.home_outlined,
          size: 64,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildDetailChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  bool _hasOptionalDetails() {
    return property.bedrooms != null ||
        property.bathrooms != null ||
        property.squareFootage != null ||
        property.propertyType != null;
  }
}
