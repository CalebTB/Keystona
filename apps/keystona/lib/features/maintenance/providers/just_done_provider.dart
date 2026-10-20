import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/task_undo.dart';

part 'just_done_provider.g.dart';

/// The overdue task the user just finished from the Tasks tab, so the tab can
/// say "done — nothing overdue" with an Undo until they leave or refresh.
@riverpod
class JustDone extends _$JustDone {
  @override
  TaskUndo? build() => null;

  void set(TaskUndo? value) => state = value;
}
