import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/supabase_service.dart';
import '../../documents/providers/documents_provider.dart';
import '../../emergency/providers/emergency_hub_provider.dart';
import '../models/task_log_draft.dart';
import '../repositories/supabase_task_detail_repository.dart';
import '../repositories/task_detail_repository.dart';

part 'task_repositories_provider.g.dart';

/// Data-access seam for the Task detail, Log and History screens. Tests
/// override it with a fake so nothing reaches Supabase.
@riverpod
TaskDetailRepository taskDetailRepository(Ref ref) =>
    SupabaseTaskDetailRepository(SupabaseService.client);

/// Pros from Who to call, for "A pro" on the Log screen. Favorites first.
@riverpod
Future<List<TaskPro>> taskPros(Ref ref) async {
  final contacts = await ref
      .read(emergencyHubProvider.notifier)
      .getContactsForPicker();
  return [
    for (final c in contacts)
      TaskPro(
        id: c.id,
        name: c.name,
        company: c.companyName,
        phone: c.phonePrimary,
      ),
  ];
}

/// Documents that can be linked to a log as its receipt.
@riverpod
Future<List<ReceiptOption>> taskReceiptOptions(Ref ref) async {
  final docs = await ref.watch(documentsProvider.future);
  return [for (final d in docs) ReceiptOption(id: d.id, name: d.name)];
}
