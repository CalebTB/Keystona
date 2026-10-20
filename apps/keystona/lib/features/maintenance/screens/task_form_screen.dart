import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/maintenance_task.dart';
import '../models/task_draft.dart';
import '../models/task_form_options.dart';
import '../models/task_link_option.dart';
import '../providers/reminders_providers.dart';
import '../providers/maintenance_tasks_provider.dart';
import '../providers/task_detail_provider.dart';
import '../providers/task_form_providers.dart';
import '../repositories/task_form_repository.dart';
import '../task_form_copy.dart';
import '../widgets/form/task_form_body.dart';
import '../widgets/form/task_form_header.dart';
import '../widgets/form/task_form_skeleton.dart';

/// Add a task (kit: AddTask), and the same form to edit one.
///
/// - Create: nothing passed; saves a new task for the home.
/// - Edit: pass [existingTask], or only its [taskId] to load it.
class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen({super.key, this.existingTask, this.taskId, this.today});

  /// The task to edit, when the caller already has it.
  final MaintenanceTask? existingTask;

  /// The task to edit, when only its id is known (loaded on open).
  final String? taskId;

  /// Today's date; tests pass a fixed one.
  final DateTime? today;

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _name = TextEditingController();
  final _notes = TextEditingController();
  final _cost = TextEditingController();
  final _supplies = TextEditingController();

  late final DateTime _today = TaskDraft.dateOnly(
    widget.today ?? DateTime.now(),
  );

  /// The form's answers; null until the person changes something.
  TaskDraft? _edited;

  /// True once the controllers hold the first answers.
  bool _seeded = false;
  bool _saving = false;

  String? get _editId => widget.existingTask?.id ?? widget.taskId;
  bool get _isEditing => _editId != null;

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    _cost.dispose();
    _supplies.dispose();
    super.dispose();
  }

  void _seed(TaskDraft draft) {
    _name.text = draft.name;
    _notes.text = draft.notes;
    _cost.text = draft.cost;
    _supplies.text = draft.supplies;
    _seeded = true;
  }

  /// Keeps the text fields in step with answers that change from elsewhere
  /// (a tapped suggestion).
  void _sync(TaskDraft draft) {
    if (_name.text != draft.name) _name.text = draft.name;
    if (_notes.text != draft.notes) _notes.text = draft.notes;
    if (_cost.text != draft.cost) _cost.text = draft.cost;
    if (_supplies.text != draft.supplies) _supplies.text = draft.supplies;
  }

  void _change(TaskDraft draft) {
    _sync(draft);
    setState(() => _edited = draft);
  }

  TaskLinkOption? _linkFor(MaintenanceTask task, List<TaskLinkOption> options) {
    final id = task.linkedSystemId ?? task.linkedApplianceId;
    if (id == null) return null;
    return options.where((o) => o.id == id).firstOrNull;
  }

  Future<void> _pickDate(TaskDraft draft) async {
    final current = draft.dueDate(_today);
    final first = current.isBefore(_today) ? current : _today;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: first,
      lastDate: DateTime(
        _today.year + TaskDraft.maxYearsAhead,
        _today.month,
        _today.day,
      ),
    );
    if (picked == null || !mounted) return;
    _change(
      draft.copyWith(
        due: DueChoice.other,
        customDate: TaskDraft.dateOnly(picked),
      ),
    );
  }

  Future<void> _save(
    TaskDraft draft,
    String? propertyId,
    MaintenanceTask? existing,
  ) async {
    if (_saving || !draft.isReady) return;
    final repository = ref.read(taskFormRepositoryProvider);
    final container = ProviderScope.containerOf(context);
    setState(() => _saving = true);
    try {
      final id = _editId;
      if (id != null) {
        await repository.update(
          id,
          draft,
          category: existing?.category ?? draft.link!.category,
          today: _today,
        );
        container.invalidate(taskDetailProvider(id));
      } else {
        await repository.create(draft, propertyId: propertyId!, today: _today);
      }
      container
        ..invalidate(maintenanceTasksProvider)
        ..invalidate(remindersProvider);
      if (mounted) context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarService.showError(context, TaskFormCopy.saveError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formContext = ref.watch(taskFormContextProvider);
    final id = _editId;
    final loadedTask =
        widget.existingTask ??
        (widget.taskId == null
            ? null
            : ref.watch(editableTaskProvider(widget.taskId!)).value);
    final waitingForTask = _isEditing && loadedTask == null;
    final data = formContext.value;
    final propertyId = data?.propertyId;

    TaskDraft? draft = _edited;
    if (draft == null && data != null && !waitingForTask) {
      draft = loadedTask == null
          ? const TaskDraft()
          : TaskDraft.fromTask(
              loadedTask,
              link: _linkFor(loadedTask, data.options),
            );
      if (!_seeded) _seed(draft);
    }

    final canSave =
        draft != null &&
        draft.isReady &&
        !_saving &&
        (_isEditing || propertyId != null);

    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: AuroraColors.paper,
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: context.aurora.contentMaxWidth,
              ),
              child: Column(
                children: [
                  TaskFormHeader(
                    title: id == null
                        ? TaskFormCopy.title
                        : TaskFormCopy.editTitle,
                    onCancel: _saving ? null : () => context.pop(),
                    onSave: canSave
                        ? () => _save(draft!, propertyId, loadedTask)
                        : null,
                    saving: _saving,
                  ),
                  Expanded(child: _content(formContext, data, draft)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(
    AsyncValue<TaskFormContext> formContext,
    TaskFormContext? data,
    TaskDraft? draft,
  ) {
    if (formContext.hasError && data == null) {
      return ErrorView(
        message: TaskFormCopy.loadError,
        onRetry: () => ref.invalidate(taskFormContextProvider),
      );
    }
    if (data == null || draft == null) return const TaskFormSkeleton();
    if (data.propertyId == null && !_isEditing) {
      return ErrorView(
        message: TaskFormCopy.loadError,
        onRetry: () => ref.invalidate(taskFormContextProvider),
      );
    }
    return TaskFormBody(
      draft: draft,
      options: data.options,
      today: _today,
      nameController: _name,
      notesController: _notes,
      costController: _cost,
      suppliesController: _supplies,
      onChanged: _change,
      onPickDate: () => _pickDate(draft),
    );
  }
}
