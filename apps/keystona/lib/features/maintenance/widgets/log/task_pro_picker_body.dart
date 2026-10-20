import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task_log_draft.dart';
import '../../providers/task_repositories_provider.dart';
import 'task_pick_list.dart';

/// Body of the "Who did it?" sheet: your pros from Who to call. Pops with the
/// chosen [TaskPro].
class TaskProPickerBody extends ConsumerWidget {
  const TaskProPickerBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pros = ref.watch(taskProsProvider);
    return TaskPickList(
      emptyText: 'Nobody in Who to call yet. Add a contact there first.',
      onRetry: () => ref.invalidate(taskProsProvider),
      items: pros.whenData(
        (list) => [
          for (final p in list)
            TaskPickItem(
              title: p.display,
              subtitle: p.company != null && p.company!.isNotEmpty
                  ? p.name
                  : p.phone,
            ),
        ],
      ),
      onPick: (i) => Navigator.of(context).pop(pros.requireValue[i]),
    );
  }
}
