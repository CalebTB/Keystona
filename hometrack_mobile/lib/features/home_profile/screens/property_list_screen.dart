import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hometrack_mobile/features/home_profile/models/property.dart';
import 'package:hometrack_mobile/features/home_profile/providers/property_providers.dart';
import 'package:hometrack_mobile/features/home_profile/screens/property_detail_screen.dart';
import 'package:hometrack_mobile/features/home_profile/screens/property_setup_screen.dart';
import 'package:hometrack_mobile/features/home_profile/widgets/property_card.dart';

class PropertyListScreen extends ConsumerWidget {
  const PropertyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(userPropertiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Properties'),
      ),
      body: propertiesAsync.when(
        data: (properties) {
          if (properties.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(refreshPropertiesProvider)();
              // Wait for the refresh to complete
              await ref.read(userPropertiesProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: properties.length,
              itemBuilder: (context, index) {
                final property = properties[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PropertyCard(
                    property: property,
                    onTap: () => _navigateToDetail(context, ref, property),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, ref, error),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToSetup(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Property'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_outlined,
              size: 96,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'No Properties Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first property to get started tracking your home details, maintenance, and value.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _navigateToSetup(context, null),
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Property'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 96,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to Load Properties',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => ref.read(refreshPropertiesProvider)(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToSetup(BuildContext context, WidgetRef? ref) async {
    await Navigator.of(context).push<Property>(
      MaterialPageRoute(
        builder: (context) => const PropertySetupScreen(),
      ),
    );

    // Refresh is already handled in PropertySetupScreen
  }

  Future<void> _navigateToDetail(
    BuildContext context,
    WidgetRef ref,
    Property property,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PropertyDetailScreen(property: property),
      ),
    );

    // Refresh after returning from detail screen in case property was updated/deleted
    ref.read(refreshPropertiesProvider)();
  }
}
