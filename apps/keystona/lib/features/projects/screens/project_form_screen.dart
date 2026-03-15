import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/photo_picker.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../../../core/widgets/upgrade_sheet.dart';
import '../../../features/subscription/providers/subscription_provider.dart';
import '../../../services/providers/service_providers.dart';
import '../../../services/supabase_service.dart';
import '../models/project.dart';
import '../providers/projects_provider.dart';

// ── Main screen ───────────────────────────────────────────────────────────────

/// Full-screen form for creating or editing a project.
///
/// - Create mode: pass [existingProject] = null. Inserts a new row on save.
/// - Edit mode: pass [existingProject]. Updates the existing row on save.
///
/// Pops with the project ID (String) on successful save so callers can
/// navigate to the project detail screen.
class ProjectFormScreen extends ConsumerStatefulWidget {
  const ProjectFormScreen({super.key, this.existingProject});

  final Project? existingProject;

  @override
  ConsumerState<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends ConsumerState<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Controllers ───────────────────────────────────────────────────────────

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _budgetController;

  // ── Local state ───────────────────────────────────────────────────────────

  late String _projectType;
  late String _status;
  late String _workType;
  DateTime? _plannedStartDate;
  DateTime? _plannedEndDate;

  /// Local file picked but not yet uploaded.
  File? _localCoverPhoto;

  /// Storage path already saved to DB (edit mode).
  String? _existingCoverPhotoPath;

  bool _saving = false;

  bool get _isEditing => widget.existingProject != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProject;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _budgetController = TextEditingController(
      text: p?.estimatedBudget != null
          ? p!.estimatedBudget!.toStringAsFixed(0)
          : '',
    );
    _projectType = p?.projectType ?? 'kitchen_remodel';
    _status = p?.status ?? 'planning';
    _workType = p?.workType ?? 'diy';
    _plannedStartDate = p?.plannedStartDate;
    _plannedEndDate = p?.plannedEndDate;
    _existingCoverPhotoPath = p?.coverPhotoPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  // ── Cover photo ───────────────────────────────────────────────────────────

  Future<void> _pickCoverPhoto() async {
    final file = await PhotoPicker.showPicker(context);
    if (file == null) return;
    setState(() => _localCoverPhoto = file);
  }

  Future<String?> _uploadCoverPhoto(String projectId) async {
    if (_localCoverPhoto == null) return _existingCoverPhotoPath;

    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return null;

    final storage = ref.read(storageServiceProvider);
    final ext = _localCoverPhoto!.path.split('.').last;
    final path = '${user.id}/$projectId/cover.$ext';
    return storage.uploadFile(
      bucket: 'project-photos',
      path: path,
      file: _localCoverPhoto!,
      contentType: 'image/${ext == 'jpg' ? 'jpeg' : ext}',
    );
  }

  // ── Date pickers ──────────────────────────────────────────────────────────

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_plannedStartDate ?? DateTime.now())
        : (_plannedEndDate ?? (_plannedStartDate ?? DateTime.now()));

    if (Theme.of(context).platform == TargetPlatform.iOS) {
      await _pickDateIOS(initial: initial, isStart: isStart);
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2000),
        lastDate: DateTime(2050),
      );
      if (picked != null) {
        setState(() {
          if (isStart) {
            _plannedStartDate = picked;
          } else {
            _plannedEndDate = picked;
          }
        });
      }
    }
  }

  Future<void> _pickDateIOS({
    required DateTime initial,
    required bool isStart,
  }) async {
    DateTime picked = initial;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
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
                    setState(() {
                      if (isStart) {
                        _plannedStartDate = picked;
                      } else {
                        _plannedEndDate = picked;
                      }
                    });
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initial,
                minimumDate: DateTime(2000),
                maximumDate: DateTime(2050),
                onDateTimeChanged: (d) => picked = d,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Enum pickers ──────────────────────────────────────────────────────────

  Future<void> _pickEnumIOS<T>({
    required List<({String value, String label})> options,
    required String current,
    required ValueChanged<String> onSelected,
  }) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: options
            .map(
              (o) => CupertinoActionSheetAction(
                onPressed: () {
                  onSelected(o.value);
                  Navigator.of(ctx, rootNavigator: true).pop();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        o.label,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: o.value == current
                              ? AppColors.goldAccent
                              : AppColors.textPrimary,
                          fontWeight: o.value == current
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final notifier = ref.read(projectsProvider.notifier);
      final budget = double.tryParse(_budgetController.text.trim());

      if (_isEditing) {
        final id = widget.existingProject!.id;
        final photoPath = await _uploadCoverPhoto(id);
        await notifier.updateProject(id, {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          'project_type': _projectType,
          'status': _status,
          'work_type': _workType,
          'estimated_budget': ?budget,
          'planned_start_date':
              ?(_plannedStartDate?.toIso8601String().split('T')[0]),
          'planned_end_date':
              ?(_plannedEndDate?.toIso8601String().split('T')[0]),
          'cover_photo_path': ?photoPath,
        });
        if (!mounted) return;
        context.pop(id);
      } else {
        final id = await notifier.createProject({
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          'project_type': _projectType,
          'status': _status,
          'work_type': _workType,
          'estimated_budget': ?budget,
          'planned_start_date':
              ?(_plannedStartDate?.toIso8601String().split('T')[0]),
          'planned_end_date':
              ?(_plannedEndDate?.toIso8601String().split('T')[0]),
        });

        // Upload cover photo now that we have the project ID.
        if (_localCoverPhoto != null) {
          final photoPath = await _uploadCoverPhoto(id);
          if (photoPath != null) {
            await notifier.updateProject(id, {'cover_photo_path': photoPath});
          }
        }

        if (!mounted) return;
        context.pop(id);
      }
    } on ProjectLimitException {
      if (!mounted) return;
      setState(() => _saving = false);
      await UpgradeSheet.show(
        context,
        config: const UpgradeSheetConfig(
          headline: 'Unlock Unlimited Projects',
          reason: 'Free accounts are limited to 2 active projects.',
          features: [
            'Unlimited home improvement projects',
            'Full budget tracking',
            'Before & after photo comparisons',
            'Contractor management',
          ],
          triggerKey: 'project_limit',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarService.showError(
        context,
        'Could not save project. Please try again.',
      );
    }
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
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Cancel'),
          onPressed: () => context.pop(),
        ),
        middle: Text(_isEditing ? 'Edit Project' : 'New Project'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _saving ? null : _save,
          child: _saving
              ? const CupertinoActivityIndicator()
              : Text(
                  'Save',
                  style: TextStyle(
                    color: _saving
                        ? CupertinoColors.inactiveGray
                        : CupertinoColors.activeBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppPadding.screen,
            children: [
              _CoverPhotoField(
                localFile: _localCoverPhoto,
                existingPath: _existingCoverPhotoPath,
                onTap: _pickCoverPhoto,
              ),
              const SizedBox(height: AppSizes.md),
              _SectionHeader('Project Details'),
              _FormField(
                label: 'Project name',
                child: TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 100,
                  decoration: _inputDecoration('e.g. Kitchen Remodel'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              _FormField(
                label: 'Description',
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: _inputDecoration('Optional notes or scope'),
                ),
              ),
              _SectionHeader('Classification'),
              _TapRow(
                label: 'Type',
                value: _projectType.projectTypeLabel,
                onTap: () => _pickEnumIOS(
                  options: ProjectTypes.all,
                  current: _projectType,
                  onSelected: (v) => setState(() => _projectType = v),
                ),
              ),
              if (_isEditing) ...[
                _TapRow(
                  label: 'Status',
                  value: _status.statusLabel,
                  onTap: () {
                    final options = ProjectStatusTransitions.nextFor(_status)
                        .map((v) => ProjectStatuses.all
                            .firstWhere((s) => s.value == v))
                        .toList();
                    if (options.isEmpty) return;
                    _pickEnumIOS(
                      options: options,
                      current: _status,
                      onSelected: (v) => setState(() => _status = v),
                    );
                  },
                ),
              ],
              _TapRow(
                label: 'Work type',
                value: _workType.workTypeLabel,
                onTap: () => _pickEnumIOS(
                  options: ProjectWorkTypes.all,
                  current: _workType,
                  onSelected: (v) => setState(() => _workType = v),
                ),
              ),
              _SectionHeader('Budget & Timeline'),
              _FormField(
                label: 'Estimated budget',
                child: TextFormField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('\$0').copyWith(prefixText: '\$'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (double.tryParse(v.trim()) == null) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
              ),
              _DateRow(
                label: 'Planned start',
                date: _plannedStartDate,
                onTap: () => _pickDate(isStart: true),
                onClear: _plannedStartDate != null
                    ? () => setState(() => _plannedStartDate = null)
                    : null,
              ),
              _DateRow(
                label: 'Planned end',
                date: _plannedEndDate,
                onTap: () => _pickDate(isStart: false),
                onClear: _plannedEndDate != null
                    ? () => setState(() => _plannedEndDate = null)
                    : null,
              ),
              const SizedBox(height: AppSizes.xl),
            ],
          ),
        ),
      ),
    );
  }

  // ── Android layout ────────────────────────────────────────────────────────

  Widget _buildAndroid() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(_isEditing ? 'Edit Project' : 'New Project'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(AppSizes.sm),
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppPadding.screen,
          children: [
            _CoverPhotoField(
              localFile: _localCoverPhoto,
              existingPath: _existingCoverPhotoPath,
              onTap: _pickCoverPhoto,
            ),
            const SizedBox(height: AppSizes.md),
            _SectionHeader('Project Details'),
            _FormField(
              label: 'Project name',
              child: TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                maxLength: 100,
                decoration: _inputDecoration('e.g. Kitchen Remodel'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ),
            _FormField(
              label: 'Description',
              child: TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 500,
                decoration: _inputDecoration('Optional notes or scope'),
              ),
            ),
            _SectionHeader('Classification'),
            _FormField(
              label: 'Type',
              child: DropdownButtonFormField<String>(
                initialValue: _projectType,
                decoration: _inputDecoration(''),
                onChanged: (v) => setState(() => _projectType = v!),
                items: ProjectTypes.all
                    .map((t) => DropdownMenuItem(
                          value: t.value,
                          child: Text(t.label),
                        ))
                    .toList(),
              ),
            ),
            if (_isEditing) ...[
              _FormField(
                label: 'Status',
                child: DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: _inputDecoration(''),
                  onChanged: (v) => setState(() => _status = v!),
                  items: ProjectStatusTransitions.nextFor(_status)
                      .map((v) => ProjectStatuses.all
                          .firstWhere((s) => s.value == v))
                      .map((s) => DropdownMenuItem(
                            value: s.value,
                            child: Text(s.label),
                          ))
                      .toList(),
                ),
              ),
            ],
            _FormField(
              label: 'Work type',
              child: DropdownButtonFormField<String>(
                initialValue: _workType,
                decoration: _inputDecoration(''),
                onChanged: (v) => setState(() => _workType = v!),
                items: ProjectWorkTypes.all
                    .map((t) => DropdownMenuItem(
                          value: t.value,
                          child: Text(t.label),
                        ))
                    .toList(),
              ),
            ),
            _SectionHeader('Budget & Timeline'),
            _FormField(
              label: 'Estimated budget',
              child: TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('\$0').copyWith(prefixText: '\$'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (double.tryParse(v.trim()) == null) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
            ),
            _DateRow(
              label: 'Planned start',
              date: _plannedStartDate,
              onTap: () => _pickDate(isStart: true),
              onClear: _plannedStartDate != null
                  ? () => setState(() => _plannedStartDate = null)
                  : null,
            ),
            _DateRow(
              label: 'Planned end',
              date: _plannedEndDate,
              onTap: () => _pickDate(isStart: false),
              onClear: _plannedEndDate != null
                  ? () => setState(() => _plannedEndDate = null)
                  : null,
            ),
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.gray400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
      );
}

// ── Shared form widgets ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.md, bottom: AppSizes.xs),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSizes.xs),
          child,
        ],
      ),
    );
  }
}

/// Tappable row for iOS enum pickers.
class _TapRow extends StatelessWidget {
  const _TapRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm + 2,
        ),
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(value, style: AppTextStyles.bodyLarge),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.gray400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tappable date row with optional clear button.
class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.date,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final formatted =
        date != null ? DateFormat('MMM d, yyyy').format(date!) : 'Not set';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm + 2,
        ),
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatted,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color:
                          date == null ? AppColors.gray400 : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(
                  Icons.clear,
                  color: AppColors.gray400,
                  size: 18,
                ),
              )
            else
              const Icon(
                Icons.calendar_today_outlined,
                color: AppColors.gray400,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

/// Cover photo field — tappable placeholder or thumbnail.
class _CoverPhotoField extends StatelessWidget {
  const _CoverPhotoField({
    required this.localFile,
    required this.existingPath,
    required this.onTap,
  });

  final File? localFile;
  final String? existingPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = localFile != null || existingPath != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasPhoto
            ? _buildPhoto()
            : _buildPlaceholder(context),
      ),
    );
  }

  Widget _buildPhoto() {
    if (localFile != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(localFile!, fit: BoxFit.cover),
          Positioned(
            bottom: AppSizes.sm,
            right: AppSizes.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Text(
                'Tap to change',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textInverse),
              ),
            ),
          ),
        ],
      );
    }
    // existingPath is set but no new file — show a placeholder with edit hint.
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: AppColors.gray200),
        const Center(
          child: Icon(Icons.image_outlined, color: AppColors.gray400, size: 40),
        ),
        Positioned(
          bottom: AppSizes.sm,
          right: AppSizes.sm,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Text(
              'Tap to change',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.textInverse),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.add_photo_alternate_outlined,
          color: AppColors.gray400,
          size: 36,
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          'Add cover photo (optional)',
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
