import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task_log_draft.dart';
import '../../providers/task_repositories_provider.dart';
import 'task_pick_list.dart';

/// Body of the "Link a receipt" sheet: your documents. Pops with the chosen
/// [ReceiptOption].
class TaskReceiptPickerBody extends ConsumerWidget {
  const TaskReceiptPickerBody({super.key, this.exclude = const {}});

  /// Ids already linked, which are not offered again.
  final Set<String> exclude;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref.watch(taskReceiptOptionsProvider);
    final options = docs.whenData(
      (list) => [
        for (final d in list)
          if (!exclude.contains(d.id)) d,
      ],
    );
    return TaskPickList(
      emptyText: 'No documents to link yet. Add the receipt to Docs first.',
      onRetry: () => ref.invalidate(taskReceiptOptionsProvider),
      items: options.whenData(
        (list) => [for (final d in list) TaskPickItem(title: d.name)],
      ),
      onPick: (i) => Navigator.of(context).pop(options.requireValue[i]),
    );
  }
}
