import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../../../services/supabase_service.dart';
import '../models/maintenance_task.dart';
import '../providers/maintenance_tasks_provider.dart';
import '../providers/task_form_providers.dart';

// ── Task category catalog ─────────────────────────────────────────────────────

/// Predefined task category values stored in the `category` TEXT column.
///
/// Matches the values used in maintenance templates and the DB schema comment.
abstract final class TaskCategories {
  static const all = [
    (value: 'hvac', label: 'HVAC'),
    (value: 'plumbing', label: 'Plumbing'),
    (value: 'exterior', label: 'Exterior'),
    (value: 'interior', label: 'Interior'),
    (value: 'safety', label: 'Safety'),
    (value: 'seasonal', label: 'Seasonal'),
    (value: 'electrical', label: 'Electrical'),
    (value: 'landscaping', label: 'Landscaping'),
    (value: 'appliance', label: 'Appliance'),
    (value: 'other', label: 'Other'),
  ];

  static String labelFor(String value) =>
      all.firstWhere((c) => c.value == value, orElse: () => (value: value, label: value)).label;
}

// ── Main screen ───────────────────────────────────────────────────────────────

/// Full-screen form for creating or editing a custom maintenance task.
///
/// - Create mode: pass [existingTask] = null. The form starts blank with
///   sensible defaults and inserts a new row on save.
/// - Edit mode: pass [existingTask]. All fields are pre-populated and the
///   existing row is updated on save.
class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen({super.key, this.existingTask});

  /// The task to edit, or null when creating a new task.
  final MaintenanceTask? existingTask;

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Controllers ───────────────────────────────────────────────────────────

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _toolsController;
  late final TextEditingController _suppliesController;
  late final TextEditingController _estHoursController;

  // ── Local state ───────────────────────────────────────────────────────────

  late String _category;
  late DateTime _dueDate;
  late RecurrenceType _recurrence;
  late TaskPriority _priority;
  late TaskDifficulty _difficulty;
  late DiyOrPro _diyOrPro;
  String? _linkedSystemId;
  String? _linkedApplianceId;
  String? _propertyId;

  bool _saving = false;

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    final t = widget.existingTask;
    _titleController = TextEditingController(text: t?.name ?? '');
    _descriptionController = TextEditingController(text: t?.description ?? '');
    _toolsController = TextEditingController(
      text: t != null && t.toolsNeeded.isNotEmpty ? t.toolsNeeded.join('\n') : '',
    );
    _suppliesController = TextEditingController(
      text: t != null && t.suppliesNeeded.isNotEmpty ? t.suppliesNeeded.join('\n') : '',
    );
    final estHours = t?.estimatedMinutes != null ? (t!.estimatedMinutes! / 60.0) : null;
    _estHoursController = TextEditingController(
      text: estHours != null
          ? (estHours == estHours.truncateToDouble()
              ? estHours.toInt().toString()
              : estHours.toStringAsFixed(1))
          : '',
    );

    _category = t?.category ?? 'hvac';
    _dueDate = t?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    _recurrence = t?.recurrence ?? RecurrenceType.none;
    _priority = t?.priority ?? TaskPriority.medium;
    _difficulty = t?.difficulty ?? TaskDifficulty.easy;
    _diyOrPro = t?.diyOrPro ?? DiyOrPro.diy;
    _linkedSystemId = t?.linkedSystemId;
    _linkedApplianceId = t?.linkedApplianceId;

    // Resolve property ID for picker providers.
    _resolvePropertyId();
  }

  Future<void> _resolvePropertyId() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return;
    final row = await SupabaseService.client
        .from('properties')
        .select('id')
        .eq('user_id', user.id)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (mounted && row != null) {
      setState(() => _propertyId = row['id'] as String);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _toolsController.dispose();
    _suppliesController.dispose();
    _estHoursController.dispose();
    super.dispose();
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    // Parse estimated hours → minutes.
    int? estMinutes;
    final hoursText = _estHoursController.text.trim();
    if (hoursText.isNotEmpty) {
      final hours = double.tryParse(hoursText);
      if (hours != null && hours > 0) {
        estMinutes = (hours * 60).round();
      }
    }

    // Parse tools/supplies: split by newline, trim, drop blanks.
    final tools = _toolsController.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final supplies = _suppliesController.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    try {
      final notifier = ref.read(maintenanceTasksProvider.notifier);

      if (_isEditing) {
        await notifier.updateTask(widget.existingTask!.id, {
          'name': _titleController.text.trim(),
          'description': _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          'category': _category,
          'due_date': DateFormat('yyyy-MM-dd').format(_dueDate),
          'recurrence': _recurrence.value,
          'priority': _priority.value,
          'difficulty': _difficulty.value,
          'diy_or_pro': _diyOrPro.value,
          'estimated_minutes': estMinutes,
          'tools_needed': tools,
          'supplies_needed': supplies,
          'linked_system_id': _linkedSystemId,
          'linked_appliance_id': _linkedApplianceId,
        });
      } else {
        final user = SupabaseService.client.auth.currentUser!;
        await notifier.addTask({
          'property_id': _propertyId,
          'user_id': user.id,
          'task_origin': 'custom',
          'name': _titleController.text.trim(),
          'description': _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          'category': _category,
          'due_date': DateFormat('yyyy-MM-dd').format(_dueDate),
          'recurrence': _recurrence.value,
          'priority': _priority.value,
          'difficulty': _difficulty.value,
          'diy_or_pro': _diyOrPro.value,
          'estimated_minutes': estMinutes,
          'tools_needed': tools,
          'supplies_needed': supplies,
          'linked_system_id': _linkedSystemId,
          'linked_appliance_id': _linkedApplianceId,
        });
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        SnackbarService.showError(context, "Couldn't save task. Try again.");
      }
    }
  }

  // ── Date picker ───────────────────────────────────────────────────────────

  Future<void> _pickDueDate() async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIOS) {
      await _pickDateIOS();
    } else {
      await _pickDateAndroid();
    }
  }

  Future<void> _pickDateIOS() async {
    DateTime picked = _dueDate;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: AppColors.surface,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('Cancel'),
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                ),
                CupertinoButton(
                  child: const Text('Done'),
                  onPressed: () {
                    setState(() => _dueDate = picked);
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _dueDate,
                onDateTimeChanged: (d) => picked = d,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateAndroid() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _dueDate = picked);
  }

  // ── Entity pickers ────────────────────────────────────────────────────────

  Future<void> _pickLinkedSystem(List<PickerOption> options) async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    await _showEntityPicker(
      title: 'Link to System',
      options: options,
      currentId: _linkedSystemId,
      isIOS: isIOS,
      onSelected: (id) => setState(() => _linkedSystemId = id),
    );
  }

  Future<void> _pickLinkedAppliance(List<PickerOption> options) async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    await _showEntityPicker(
      title: 'Link to Appliance',
      options: options,
      currentId: _linkedApplianceId,
      isIOS: isIOS,
      onSelected: (id) => setState(() => _linkedApplianceId = id),
    );
  }

  Future<void> _showEntityPicker({
    required String title,
    required List<PickerOption> options,
    required String? currentId,
    required bool isIOS,
    required void Function(String? id) onSelected,
  }) async {
    if (isIOS) {
      await showCupertinoModalPopup<void>(
        context: context,
        builder: (_) => CupertinoActionSheet(
          title: Text(title),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                onSelected(null);
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: const Text('None'),
            ),
            ...options.map(
              (opt) => CupertinoActionSheetAction(
                isDefaultAction: opt.id == currentId,
                onPressed: () {
                  onSelected(opt.id);
                  Navigator.of(context, rootNavigator: true).pop();
                },
                child: Text(opt.name),
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Cancel'),
          ),
        ),
      );
    } else {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
        ),
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: AppPadding.card,
                child: Text(title, style: AppTextStyles.h3),
              ),
              ListTile(
                title: const Text('None'),
                onTap: () {
                  onSelected(null);
                  Navigator.of(context).pop();
                },
              ),
              ...options.map(
                (opt) => ListTile(
                  title: Text(opt.name),
                  trailing: opt.id == currentId
                      ? const Icon(Icons.check, color: AppColors.deepNavy)
                      : null,
                  onTap: () {
                    onSelected(opt.id);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // ── Enum pickers (iOS) ────────────────────────────────────────────────────

  Future<void> _pickEnumIOS<T>({
    required String title,
    required List<(T value, String label)> options,
    required T current,
    required void Function(T) onSelected,
  }) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(title),
        actions: options
            .map(
              (opt) => CupertinoActionSheetAction(
                isDefaultAction: opt.$1 == current,
                onPressed: () {
                  onSelected(opt.$1);
                  Navigator.of(context, rootNavigator: true).pop();
                },
                child: Text(opt.$2),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return isIOS ? _buildIOS() : _buildAndroid();
  }

  // ── iOS layout ────────────────────────────────────────────────────────────

  Widget _buildIOS() {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_isEditing ? 'Edit Task' : 'New Task'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _saving ? null : () => context.pop(),
          child: const Text('Cancel'),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _saving ? null : _save,
          child: _saving
              ? const CupertinoActivityIndicator()
              : const Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: _FormBody(
          formKey: _formKey,
          isIOS: true,
          saving: _saving,
          titleController: _titleController,
          descriptionController: _descriptionController,
          toolsController: _toolsController,
          suppliesController: _suppliesController,
          estHoursController: _estHoursController,
          category: _category,
          dueDate: _dueDate,
          recurrence: _recurrence,
          priority: _priority,
          difficulty: _difficulty,
          diyOrPro: _diyOrPro,
          linkedSystemId: _linkedSystemId,
          linkedApplianceId: _linkedApplianceId,
          propertyId: _propertyId,
          onCategoryTap: () => _pickEnumIOS(
            title: 'Category',
            options: TaskCategories.all
                .map((c) => (c.value, c.label))
                .toList(),
            current: _category,
            onSelected: (v) => setState(() => _category = v),
          ),
          onDueDateTap: _pickDueDate,
          onRecurrenceTap: () => _pickEnumIOS(
            title: 'Recurrence',
            options: RecurrenceType.values
                .map((r) => (r, r.label))
                .toList(),
            current: _recurrence,
            onSelected: (v) => setState(() => _recurrence = v),
          ),
          onPriorityTap: () => _pickEnumIOS(
            title: 'Priority',
            options: [
              (TaskPriority.low, 'Low'),
              (TaskPriority.medium, 'Medium'),
              (TaskPriority.high, 'High'),
            ],
            current: _priority,
            onSelected: (v) => setState(() => _priority = v),
          ),
          onDifficultyTap: () => _pickEnumIOS(
            title: 'Difficulty',
            options: [
              (TaskDifficulty.easy, 'Easy'),
              (TaskDifficulty.moderate, 'Moderate'),
              (TaskDifficulty.involved, 'Involved'),
              (TaskDifficulty.professional, 'Professional'),
            ],
            current: _difficulty,
            onSelected: (v) => setState(() => _difficulty = v),
          ),
          onDiyOrProTap: () => _pickEnumIOS(
            title: 'Recommendation',
            options: [
              (DiyOrPro.diy, 'DIY'),
              (DiyOrPro.either, 'Either'),
              (DiyOrPro.professional, 'Professional'),
            ],
            current: _diyOrPro,
            onSelected: (v) => setState(() => _diyOrPro = v),
          ),
          onSystemTap: (options) => _pickLinkedSystem(options),
          onApplianceTap: (options) => _pickLinkedAppliance(options),
        ),
      ),
    );
  }

  // ── Android layout ────────────────────────────────────────────────────────

  Widget _buildAndroid() {
    return Scaffold(
      backgroundColor: AppColors.warmOffWhite,
      appBar: AppBar(
        backgroundColor: AppColors.warmOffWhite,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Task' : 'New Task',
          style: AppTextStyles.h3,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _saving ? null : () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.sm),
            child: _saving
                ? const Center(
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.deepNavy,
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: _save,
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        color: AppColors.deepNavy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: _FormBody(
        formKey: _formKey,
        isIOS: false,
        saving: _saving,
        titleController: _titleController,
        descriptionController: _descriptionController,
        toolsController: _toolsController,
        suppliesController: _suppliesController,
        estHoursController: _estHoursController,
        category: _category,
        dueDate: _dueDate,
        recurrence: _recurrence,
        priority: _priority,
        difficulty: _difficulty,
        diyOrPro: _diyOrPro,
        linkedSystemId: _linkedSystemId,
        linkedApplianceId: _linkedApplianceId,
        propertyId: _propertyId,
        onCategoryTap: () async {
          final result = await showModalBottomSheet<String>(
            context: context,
            backgroundColor: AppColors.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSizes.radiusLg),
              ),
            ),
            builder: (_) => _CategoryPicker(current: _category),
          );
          if (result != null && mounted) setState(() => _category = result);
        },
        onDueDateTap: _pickDueDate,
        onRecurrenceTap: () async {
          final result = await showModalBottomSheet<RecurrenceType>(
            context: context,
            backgroundColor: AppColors.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSizes.radiusLg),
              ),
            ),
            builder: (_) => _EnumPicker<RecurrenceType>(
              title: 'Recurrence',
              options: RecurrenceType.values.map((r) => (r, r.label)).toList(),
              current: _recurrence,
            ),
          );
          if (result != null && mounted) setState(() => _recurrence = result);
        },
        onPriorityTap: () async {
          final result = await showModalBottomSheet<TaskPriority>(
            context: context,
            backgroundColor: AppColors.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSizes.radiusLg),
              ),
            ),
            builder: (_) => _EnumPicker<TaskPriority>(
              title: 'Priority',
              options: [
                (TaskPriority.low, 'Low'),
                (TaskPriority.medium, 'Medium'),
                (TaskPriority.high, 'High'),
              ],
              current: _priority,
            ),
          );
          if (result != null && mounted) setState(() => _priority = result);
        },
        onDifficultyTap: () async {
          final result = await showModalBottomSheet<TaskDifficulty>(
            context: context,
            backgroundColor: AppColors.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSizes.radiusLg),
              ),
            ),
            builder: (_) => _EnumPicker<TaskDifficulty>(
              title: 'Difficulty',
              options: [
                (TaskDifficulty.easy, 'Easy'),
                (TaskDifficulty.moderate, 'Moderate'),
                (TaskDifficulty.involved, 'Involved'),
                (TaskDifficulty.professional, 'Professional'),
              ],
              current: _difficulty,
            ),
          );
          if (result != null && mounted) setState(() => _difficulty = result);
        },
        onDiyOrProTap: () async {
          final result = await showModalBottomSheet<DiyOrPro>(
            context: context,
            backgroundColor: AppColors.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSizes.radiusLg),
              ),
            ),
            builder: (_) => _EnumPicker<DiyOrPro>(
              title: 'Recommendation',
              options: [
                (DiyOrPro.diy, 'DIY'),
                (DiyOrPro.either, 'Either'),
                (DiyOrPro.professional, 'Professional'),
              ],
              current: _diyOrPro,
            ),
          );
          if (result != null && mounted) setState(() => _diyOrPro = result);
        },
        onSystemTap: (options) => _pickLinkedSystem(options),
        onApplianceTap: (options) => _pickLinkedAppliance(options),
      ),
    );
  }
}

// ── Shared form body ──────────────────────────────────────────────────────────

/// Platform-agnostic form fields. Platform-specific wrappers own the scaffold
/// and Save/Cancel — they both render this widget as the scrollable body.
class _FormBody extends ConsumerWidget {
  const _FormBody({
    required this.formKey,
    required this.isIOS,
    required this.saving,
    required this.titleController,
    required this.descriptionController,
    required this.toolsController,
    required this.suppliesController,
    required this.estHoursController,
    required this.category,
    required this.dueDate,
    required this.recurrence,
    required this.priority,
    required this.difficulty,
    required this.diyOrPro,
    required this.linkedSystemId,
    required this.linkedApplianceId,
    required this.propertyId,
    required this.onCategoryTap,
    required this.onDueDateTap,
    required this.onRecurrenceTap,
    required this.onPriorityTap,
    required this.onDifficultyTap,
    required this.onDiyOrProTap,
    required this.onSystemTap,
    required this.onApplianceTap,
  });

  final GlobalKey<FormState> formKey;
  final bool isIOS;
  final bool saving;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController toolsController;
  final TextEditingController suppliesController;
  final TextEditingController estHoursController;
  final String category;
  final DateTime dueDate;
  final RecurrenceType recurrence;
  final TaskPriority priority;
  final TaskDifficulty difficulty;
  final DiyOrPro diyOrPro;
  final String? linkedSystemId;
  final String? linkedApplianceId;
  final String? propertyId;
  final VoidCallback onCategoryTap;
  final VoidCallback onDueDateTap;
  final VoidCallback onRecurrenceTap;
  final VoidCallback onPriorityTap;
  final VoidCallback onDifficultyTap;
  final VoidCallback onDiyOrProTap;
  final void Function(List<PickerOption>) onSystemTap;
  final void Function(List<PickerOption>) onApplianceTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemsAsync = propertyId != null
        ? ref.watch(systemPickerOptionsProvider(propertyId!))
        : const AsyncData(<PickerOption>[]);
    final appliancesAsync = propertyId != null
        ? ref.watch(appliancePickerOptionsProvider(propertyId!))
        : const AsyncData(<PickerOption>[]);

    final systems = systemsAsync.value ?? [];
    final appliances = appliancesAsync.value ?? [];

    return Form(
      key: formKey,
      child: ListView(
        padding: AppPadding.screen.copyWith(bottom: 48),
        children: [
          // ── Section: Task info ─────────────────────────────────────────
          _SectionHeader(label: 'Task Info'),
          _FormField(
            label: 'Title *',
            child: TextFormField(
              controller: titleController,
              enabled: !saving,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration('e.g. Replace air filter'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Title is required';
                return null;
              },
            ),
          ),
          _FormField(
            label: 'Description',
            child: TextFormField(
              controller: descriptionController,
              enabled: !saving,
              maxLength: 5000,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration('Optional details about this task'),
            ),
          ),
          _FormField(
            label: 'Category',
            child: _TapRow(
              value: TaskCategories.labelFor(category),
              onTap: saving ? null : onCategoryTap,
            ),
          ),

          // ── Section: Scheduling ────────────────────────────────────────
          _SectionHeader(label: 'Scheduling'),
          _FormField(
            label: 'Due Date *',
            child: _TapRow(
              value: DateFormat('MMM d, yyyy').format(dueDate),
              onTap: saving ? null : onDueDateTap,
            ),
          ),
          _FormField(
            label: 'Recurrence',
            child: _TapRow(
              value: recurrence.label,
              onTap: saving ? null : onRecurrenceTap,
            ),
          ),

          // ── Section: Task details ──────────────────────────────────────
          _SectionHeader(label: 'Task Details'),
          _FormField(
            label: 'Priority',
            child: _TapRow(
              value: _priorityLabel(priority),
              onTap: saving ? null : onPriorityTap,
            ),
          ),
          _FormField(
            label: 'Difficulty',
            child: _TapRow(
              value: _difficultyLabel(difficulty),
              onTap: saving ? null : onDifficultyTap,
            ),
          ),
          _FormField(
            label: 'Recommendation',
            child: _TapRow(
              value: _diyOrProLabel(diyOrPro),
              onTap: saving ? null : onDiyOrProTap,
            ),
          ),
          _FormField(
            label: 'Estimated Time (hours)',
            child: TextFormField(
              controller: estHoursController,
              enabled: !saving,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDecoration('e.g. 1.5'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final hours = double.tryParse(v.trim());
                if (hours == null || hours <= 0 || hours > 9999) {
                  return 'Enter a number between 0.1 and 9999';
                }
                return null;
              },
            ),
          ),

          // ── Section: Materials ─────────────────────────────────────────
          _SectionHeader(label: 'Materials'),
          _FormField(
            label: 'Tools Needed',
            child: TextFormField(
              controller: toolsController,
              enabled: !saving,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration('One per line\ne.g. Screwdriver'),
            ),
          ),
          _FormField(
            label: 'Supplies Needed',
            child: TextFormField(
              controller: suppliesController,
              enabled: !saving,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration('One per line\ne.g. Air filter'),
            ),
          ),

          // ── Section: Links ─────────────────────────────────────────────
          _SectionHeader(label: 'Links'),
          _FormField(
            label: 'Linked System',
            child: _TapRow(
              value: systems.isEmpty
                  ? 'No systems added yet'
                  : linkedSystemId != null
                      ? systems
                          .firstWhere(
                            (s) => s.id == linkedSystemId,
                            orElse: () => (id: '', name: 'Unknown'),
                          )
                          .name
                      : 'None',
              onTap: (saving || systems.isEmpty)
                  ? null
                  : () => onSystemTap(systems),
            ),
          ),
          _FormField(
            label: 'Linked Appliance',
            child: _TapRow(
              value: appliances.isEmpty
                  ? 'No appliances added yet'
                  : linkedApplianceId != null
                      ? appliances
                          .firstWhere(
                            (a) => a.id == linkedApplianceId,
                            orElse: () => (id: '', name: 'Unknown'),
                          )
                          .name
                      : 'None',
              onTap: (saving || appliances.isEmpty)
                  ? null
                  : () => onApplianceTap(appliances),
            ),
          ),
        ],
      ),
    );
  }

  static InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        counterStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: const BorderSide(color: AppColors.deepNavy),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.sm,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
      );

  static String _priorityLabel(TaskPriority p) => switch (p) {
        TaskPriority.low => 'Low',
        TaskPriority.medium => 'Medium',
        TaskPriority.high => 'High',
        TaskPriority.critical => 'Critical',
      };

  static String _difficultyLabel(TaskDifficulty d) => switch (d) {
        TaskDifficulty.easy => 'Easy',
        TaskDifficulty.moderate => 'Moderate',
        TaskDifficulty.involved => 'Involved',
        TaskDifficulty.professional => 'Professional',
      };

  static String _diyOrProLabel(DiyOrPro d) => switch (d) {
        DiyOrPro.diy => 'DIY',
        DiyOrPro.either => 'Either',
        DiyOrPro.professional => 'Professional',
      };
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.lg, bottom: AppSizes.xs),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.xs),
            child: Text(label, style: AppTextStyles.labelMedium),
          ),
          child,
        ],
      ),
    );
  }
}

/// A tappable row that mimics a form field but opens a picker.
class _TapRow extends StatelessWidget {
  const _TapRow({required this.value, required this.onTap});
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.sm,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: onTap == null
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Android-specific pickers ──────────────────────────────────────────────────

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.current});
  final String current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: AppPadding.card,
            child: Text('Category', style: AppTextStyles.h3),
          ),
          ...TaskCategories.all.map(
            (c) => ListTile(
              title: Text(c.label),
              trailing: c.value == current
                  ? const Icon(Icons.check, color: AppColors.deepNavy)
                  : null,
              onTap: () => Navigator.of(context).pop(c.value),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
        ],
      ),
    );
  }
}

class _EnumPicker<T> extends StatelessWidget {
  const _EnumPicker({
    required this.title,
    required this.options,
    required this.current,
  });

  final String title;
  final List<(T, String)> options;
  final T current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: AppPadding.card,
            child: Text(title, style: AppTextStyles.h3),
          ),
          ...options.map(
            (opt) => ListTile(
              title: Text(opt.$2),
              trailing: opt.$1 == current
                  ? const Icon(Icons.check, color: AppColors.deepNavy)
                  : null,
              onTap: () => Navigator.of(context).pop(opt.$1),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
        ],
      ),
    );
  }
}
