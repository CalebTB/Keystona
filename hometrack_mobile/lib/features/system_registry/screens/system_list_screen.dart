import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/home_system.dart';
import '../providers/system_providers.dart';
import 'system_setup_screen.dart';
import 'system_detail_screen.dart';

class SystemListScreen extends ConsumerWidget {
  final String propertyId;

  const SystemListScreen({
    super.key,
    required this.propertyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemsAsync = ref.watch(propertySystemsProvider(propertyId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Systems'),
      ),
      body: systemsAsync.when(
        data: (systems) => systems.isEmpty
            ? _buildEmptyState(context)
            : _buildSystemList(context, ref, systems),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToSetup(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add System'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_repair_service_outlined,
            size: 64,
            color: Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No systems tracked yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Track your HVAC, water heater, roof, and more',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemList(
    BuildContext context,
    WidgetRef ref,
    List<HomeSystem> systems,
  ) {
    // Group systems by type for better organization
    final grouped = <SystemType, List<HomeSystem>>{};
    for (final system in systems) {
      grouped.putIfAbsent(system.systemType, () => []).add(system);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final type = grouped.keys.elementAt(index);
        final typeSystems = grouped[type]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(type.icon, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    type.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            ...typeSystems.map((system) => _buildSystemCard(
                  context,
                  ref,
                  system,
                )),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildSystemCard(
    BuildContext context,
    WidgetRef ref,
    HomeSystem system,
  ) {
    // Inline age calculation
    final age = system.installationDate != null
        ? DateTime.now().year - system.installationDate!.year
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(system.systemType.icon),
        title: Text(system.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (system.systemSubtype != null)
              Text(system.systemSubtype!),
            if (age != null)
              Text(
                '$age years old',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        trailing: system.condition != null
            ? Chip(
                avatar: Icon(
                  system.condition!.icon,
                  size: 16,
                  color: system.condition!.color,
                ),
                label: Text(
                  system.condition!.displayName,
                  style: TextStyle(
                    color: system.condition!.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor:
                    system.condition!.color.withValues(alpha: 0.1),
              )
            : null,
        onTap: () => _navigateToDetail(context, ref, system),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading systems',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _navigateToSetup(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SystemSetupScreen(propertyId: propertyId),
      ),
    ).then((_) {
      // Invalidate to refresh list after setup
      ref.invalidate(propertySystemsProvider(propertyId));
    });
  }

  void _navigateToDetail(
    BuildContext context,
    WidgetRef ref,
    HomeSystem system,
  ) {
    ref.read(selectedSystemProvider.notifier).state = system;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SystemDetailScreen(),
      ),
    ).then((_) {
      // Clear selection and refresh list
      ref.read(selectedSystemProvider.notifier).state = null;
      ref.invalidate(propertySystemsProvider(propertyId));
    });
  }
}
