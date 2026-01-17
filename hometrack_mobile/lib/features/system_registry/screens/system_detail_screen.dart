import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/home_system.dart';
import '../providers/system_providers.dart';
import 'system_setup_screen.dart';

class SystemDetailScreen extends ConsumerWidget {
  const SystemDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final system = ref.watch(selectedSystemProvider);

    if (system == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('System Details')),
        body: const Center(child: Text('No system selected')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(system.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(context, system),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (system.photoUrl != null) _buildPhotoSection(system.photoUrl!),
          _buildInfoSection(context, system),
          const SizedBox(height: 16),
          _buildConditionSection(context, system),
          if (system.conditionNotes != null) ...[
            const SizedBox(height: 16),
            _buildNotesSection(context, system),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoSection(String photoUrl) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: CachedNetworkImage(
        imageUrl: photoUrl,
        memCacheHeight: 400,
        memCacheWidth: 600,
        placeholder: (context, url) => const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
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

  Widget _buildInfoSection(BuildContext context, HomeSystem system) {
    // Inline age calculation
    final age = system.installationDate != null
        ? DateTime.now().year - system.installationDate!.year
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(system.systemType.icon, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        system.systemType.displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (system.systemSubtype != null)
                        Text(
                          system.systemSubtype!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (system.manufacturer != null)
              _buildInfoRow(
                context,
                'Manufacturer',
                system.manufacturer!,
              ),
            if (system.modelNumber != null)
              _buildInfoRow(
                context,
                'Model Number',
                system.modelNumber!,
              ),
            if (system.installationDate != null) ...[
              _buildInfoRow(
                context,
                'Installation Date',
                '${system.installationDate!.month}/${system.installationDate!.day}/${system.installationDate!.year}',
              ),
              if (age != null)
                _buildInfoRow(
                  context,
                  'Age',
                  '$age ${age == 1 ? 'year' : 'years'}',
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionSection(BuildContext context, HomeSystem system) {
    if (system.condition == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Condition',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  system.condition!.icon,
                  color: system.condition!.color,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  system.condition!.displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: system.condition!.color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context, HomeSystem system) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              system.conditionNotes!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEdit(BuildContext context, HomeSystem system) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SystemSetupScreen(
          propertyId: system.propertyId,
          existingSystem: system,
        ),
      ),
    );
  }
}
