import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../models/maintenance_task.dart';
import '../repositories/task_form_repository.dart';

part 'task_form_providers.g.dart';

/// Data-access seam for the Add a task form. Tests override it with a fake.
@riverpod
TaskFormRepository taskFormRepository(Ref ref) =>
    SupabaseTaskFormRepository(SupabaseService.client);

/// The home and the systems and appliances a task can belong to. Auto-disposed
/// when the form closes.
@riverpod
Future<TaskFormContext> taskFormContext(Ref ref) =>
    ref.watch(taskFormRepositoryProvider).loadContext();

/// A saved task, for editing when the route carries only its id.
@riverpod
Future<MaintenanceTask?> editableTask(Ref ref, String taskId) =>
    ref.watch(taskFormRepositoryProvider).loadTask(taskId);
