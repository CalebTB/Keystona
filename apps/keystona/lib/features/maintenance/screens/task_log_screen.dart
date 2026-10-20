import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_tasks_b.dart';
import '../../../core/widgets/aurora/aurora_text_field.dart';
import '../../../core/widgets/aurora/aurora_toggle_row.dart';
import '../../../core/widgets/aurora/aurora_sheet.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/photo_picker.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/task_detail.dart';
import '../models/task_log_draft.dart';
import '../providers/task_detail_provider.dart';
import '../providers/task_repositories_provider.dart';
import '../services/task_dates.dart';
import '../services/task_format.dart';
import '../services/task_log_form_state.dart';
import '../services/task_log_input.dart';
import '../widgets/log/task_log_cost_section.dart';
import '../widgets/log/task_log_findings_section.dart';
import '../widgets/log/task_log_pair.dart';
import '../widgets/log/task_log_photos_section.dart';
import '../widgets/log/task_log_receipt_section.dart';
import '../widgets/log/task_log_skeleton.dart';
import '../widgets/log/task_log_task_card.dart';
import '../widgets/log/task_log_top_bar.dart';
import '../widgets/log/task_log_who_section.dart';
import '../widgets/log/task_pro_picker_body.dart';
import '../widgets/log/task_receipt_picker_body.dart';
import '../widgets/shared/task_parent_icon.dart';

/// "Log the details": date, time, who, cost, receipt, photos, what they found
/// and notes for a finished task.
///
/// Route: `/maintenance/complete/:taskId`. Pops with a [CompletionReceipt] so
/// the caller can offer Undo.
class TaskLogScreen extends ConsumerStatefulWidget {
  const TaskLogScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<TaskLogScreen> createState() => _TaskLogScreenState();
}

class _TaskLogScreenState extends ConsumerState<TaskLogScreen> {
  /// Picked photo types the bucket accepts.
  static const Set<String> _photoTypes = {'jpg', 'jpeg', 'png', 'heic', 'webp'};

  /// Largest photo accepted, in bytes (10 MB).
  static const int _photoMaxBytes = 10 * 1024 * 1024;

  TaskLogFormState? _form;
  TaskDetail? _detail;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Keeps Who to call loading while the screen is open, and tells the form
    // when it arrives so a pre-filled pro can be matched to an entry.
    ref.listenManual(taskProsProvider, (_, next) {
      final pros = next.value;
      if (pros != null) _form?.setKnownPros(pros);
    });
  }

  @override
  void dispose() {
    _form?.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final form = _form;
    if (form == null || !form.canSave || _saving) return;
    final notifier = ref.read(taskDetailProvider(widget.taskId).notifier);
    setState(() => _saving = true);
    final CompletionReceipt receipt;
    try {
      receipt = await notifier.logCompletion(form.buildDraft());
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarService.showError(context, "Couldn't save the log. Try again.");
      return;
    }
    if (!mounted) return;
    context.pop(receipt);
  }

  Future<void> _addPhoto() async {
    final File? file = await PhotoPicker.showPicker(context);
    if (file == null || !mounted) return;
    final name = file.path.split(Platform.pathSeparator).last;
    final ext = name.split('.').last.toLowerCase();
    final tooBig = await file.length() > _photoMaxBytes;
    if (!mounted) return;
    if (tooBig || !_photoTypes.contains(ext)) {
      SnackbarService.showError(context, "That photo can't be used.");
      return;
    }
    _form?.addPhoto(LogPhoto(path: file.path, name: name));
  }

  Future<void> _pickPro() async {
    final pro = await AuroraSheet.show<TaskPro>(
      context,
      title: 'Who did it?',
      child: const TaskProPickerBody(),
    );
    if (pro != null) _form?.setPro(pro);
  }

  Future<void> _addReceipt() async {
    final linked = {for (final r in _form?.receipts ?? <ReceiptOption>[]) r.id};
    final receipt = await AuroraSheet.show<ReceiptOption>(
      context,
      title: 'Link a receipt',
      child: TaskReceiptPickerBody(exclude: linked),
    );
    if (receipt != null) _form?.addReceipt(receipt);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(taskDetailProvider(widget.taskId));
    final loaded = async.value;
    if (loaded != null) {
      _detail = loaded;
      _form ??= TaskLogFormState(
        detail: loaded,
        today: TaskDates.dateOnly(DateTime.now()),
        pros: ref.read(taskProsProvider).value ?? const [],
      );
    }
    final form = _form;
    final detail = _detail;
    return Scaffold(
      backgroundColor: AuroraColors.paper,
      body: SafeArea(
        bottom: false,
        child: form == null || detail == null
            ? _placeholder(async.hasError)
            : ListenableBuilder(
                listenable: form,
                builder: (context, _) => Column(
                  children: [
                    TaskLogTopBar(
                      onCancel: () => context.pop(),
                      onSave: form.canSave ? _save : null,
                      saving: _saving,
                    ),
                    Expanded(child: _scroll(_formBody(detail, form))),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _placeholder(bool failed) => Column(
    children: [
      TaskLogTopBar(onCancel: () => context.pop(), onSave: null),
      Expanded(
        child: failed
            ? ErrorView(
                message: "Couldn't load this task.",
                onRetry: () =>
                    ref.invalidate(taskDetailProvider(widget.taskId)),
              )
            : _scroll(const TaskLogSkeleton()),
      ),
    ],
  );

  Widget _scroll(Widget child) {
    final a = context.aurora;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: a.contentMaxWidth),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              a.of(AuroraSpacing.screenPadH),
              a.of(AuroraSpacing.space7),
              a.of(AuroraSpacing.screenPadH),
              a.of(AuroraSpacing.space10),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _formBody(TaskDetail detail, TaskLogFormState form) {
    final a = context.aurora;
    final task = detail.task;
    final gap = SizedBox(height: a.of(AuroraSpacing.space8));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TaskLogTaskCard(
          name: task.name,
          icon: detail.parent?.kind.icon ?? Icons.home_outlined,
          meta: [
            detail.parent?.name ?? task.category,
            TaskFormat.every(
              task.recurrence,
              season: task.season,
              intervalYears: task.recurrenceIntervalYears,
            ),
            'Due ${TaskFormat.dayMonth(task.dueDate)}',
          ].join(' · '),
        ),
        gap,
        TaskLogPair(
          first: AuroraTextField(
            label: 'Done on',
            required: true,
            controller: form.date,
            hintText: 'MM / DD / YYYY',
            helperText: form.dateHelp,
            keyboardType: TextInputType.number,
            maxLength: AuroraTasksB.dateMaskLength,
            onChanged: (v) => _maskDate(form, v),
          ),
          second: AuroraTextField(
            label: 'Time it took',
            controller: form.time,
            hintText: 'e.g. 1 hr',
          ),
        ),
        gap,
        TaskLogWhoSection(
          doer: form.doer,
          pro: form.pro,
          onDoer: form.setDoer,
          onPickPro: _pickPro,
          onClearPro: form.clearPro,
        ),
        gap,
        TaskLogCostSection(
          labor: form.labor,
          parts: form.parts,
          totalText: form.totalText,
          helper: form.costHelp,
        ),
        gap,
        TaskLogReceiptSection(
          receipts: form.receipts,
          onAdd: _addReceipt,
          onRemove: form.removeReceipt,
        ),
        gap,
        TaskLogPhotosSection(
          photos: form.photos,
          onAdd: _addPhoto,
          onRemove: form.removePhotoAt,
        ),
        gap,
        TaskLogFindingsSection(
          selected: form.findings,
          onToggle: form.toggleFinding,
          notes: form.notes,
        ),
        gap,
        AuroraToggleRow(
          label: _historyLabel(detail),
          helperText: _historyHelper(detail),
          value: form.addToHistory,
          onChanged: form.setAddToHistory,
        ),
      ],
    );
  }

  /// "Add to the furnace's history".
  String _historyLabel(TaskDetail detail) {
    final p = detail.parent?.name.trim().toLowerCase();
    return p == null || p.isEmpty
        ? "Add to the task's history"
        : "Add to the $p's history";
  }

  /// "Shows on the furnace page and your Home report".
  String _historyHelper(TaskDetail detail) {
    final p = detail.parent?.name.trim().toLowerCase();
    return p == null || p.isEmpty
        ? 'Shows on the task page and your Home report'
        : 'Shows on the $p page and your Home report';
  }

  void _maskDate(TaskLogFormState form, String value) {
    final masked = TaskLogInput.maskDate(value);
    if (masked == value) return;
    form.date.value = TextEditingValue(
      text: masked,
      selection: TextSelection.collapsed(offset: masked.length),
    );
  }
}
