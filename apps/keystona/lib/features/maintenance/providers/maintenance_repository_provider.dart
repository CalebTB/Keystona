import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/maintenance_tasks_repository.dart';
import '../repositories/supabase_maintenance_tasks_repository.dart';

/// The data source behind the task providers. Tests override it with a fake.
final maintenanceTasksRepositoryProvider = Provider<MaintenanceTasksRepository>(
  (ref) => const SupabaseMaintenanceTasksRepository(),
);
