import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../models/project_phase.dart';
import '../providers/project_phases_provider.dart';

/// Full-screen form for creating or editing a project phase.
///
/// - Create mode: [existingPhase] = null
/// - Edit mode: [existingPhase] is provided
///
/// Pops with the phase ID (String) on successful save.
class PhaseFormScreen extends ConsumerStatefulWidget {
  const PhaseFormScreen({
    super.key,
    required this.projectId,
    this.existingPhase,
  });

  final String projectId;
  final ProjectPhase? existingPhase;

  @override
  ConsumerState<PhaseFormScreen> createState() => _PhaseFormScreenState();
}

class _PhaseFormScreenState extends ConsumerState<PhaseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  late String _status;
  DateTime? _plannedStartDate;
  DateTime? _plannedEndDate;

  bool _saving = false;

  bool get _isEditing => widget.existingPhase != null;

  static final _dateFmt = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    final p = widget.existingPhase;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descriptionController =
        TextEditingController(text: p?.description ?? '');
    _status = p?.status ?? 'planning';
    _plannedStartDate = p?.plannedStartDate;
    _plannedEndDate = p?.plannedEndDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ── Date pickers ──────────────────────────────────────────────────────────

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_plannedStartDate ?? DateTime.now())
        : (_plannedEndDate ?? DateTime.now());

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
      builder: (_) => Material(
        type: MaterialType.transparency,
        child: Container(
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
      ),
    );
  }

  // ── Status picker ─────────────────────────────────────────────────────────

  Future<void> _pickStatusIOS() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Phase Status'),
        actions: PhaseStatuses.all
            .map(
              (s) => CupertinoActionSheetAction(
                onPressed: () {
                  setState(() => _status = s.value);
                  Navigator.of(ctx, rootNavigator: true).pop();
                },
                child: Text(
                  s.label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: _status == s.value
                        ? AppColors.goldAccent
                        : AppColors.textPrimary,
                    fontWeight: _status == s.value
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
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

    final notifier =
        ref.read(projectPhasesProvider(widget.projectId).notifier);

    try {
      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'status': _status,
        if (_descriptionController.text.trim().isNotEmpty)
          'description': _descriptionController.text.trim(),
        if (_plannedStartDate != null)
          'planned_start_date':
              _plannedStartDate!.toIso8601String().split('T')[0],
        if (_plannedEndDate != null)
          'planned_end_date':
              _plannedEndDate!.toIso8601String().split('T')[0],
      };

      String id;
      if (_isEditing) {
        await notifier.updatePhase(widget.existingPhase!.id, data);
        id = widget.existingPhase!.id;
      } else {
        id = await notifier.createPhase(data);
      }

      if (!mounted) return;
      context.pop(id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarService.showError(
          context, 'Could not save phase. Please try again.');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return isIOS ? _buildIOS() : _buildAndroid();
  }

  Widget _buildIOS() {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Cancel'),
          onPressed: () => context.pop(),
        ),
        middle: Text(_isEditing ? 'Edit Phase' : 'New Phase'),
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
        child: _buildFormBody(isIOS: true),
      ),
    );
  }

  Widget _buildAndroid() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(_isEditing ? 'Edit Phase' : 'New Phase'),
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
      body: _buildFormBody(isIOS: false),
    );
  }

  Widget _buildFormBody({required bool isIOS}) {
    final decoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
    );

    return Form(
      key: _formKey,
      child: ListView(
        padding: AppPadding.screen,
        children: [
          // ── Name ───────────────────────────────────────────────────────
          _SectionLabel('Phase Name'),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            maxLength: 100,
            decoration: decoration.copyWith(hintText: 'e.g. Demolition'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: AppSizes.sm),

          // ── Description ────────────────────────────────────────────────
          _SectionLabel('Description (optional)'),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: decoration.copyWith(
              hintText: 'What happens during this phase?',
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          // ── Status ─────────────────────────────────────────────────────
          _SectionLabel('Status'),
          if (isIOS)
            _TapRow(
              label: 'Status',
              value: _status.phaseStatusLabel,
              onTap: _pickStatusIOS,
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: decoration,
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              },
              items: PhaseStatuses.all
                  .map((s) => DropdownMenuItem(
                        value: s.value,
                        child: Text(s.label),
                      ))
                  .toList(),
            ),
          const SizedBox(height: AppSizes.sm),

          // ── Planned dates ──────────────────────────────────────────────
          _SectionLabel('Planned Start (optional)'),
          _TapRow(
            label: 'Start date',
            value: _plannedStartDate != null
                ? _dateFmt.format(_plannedStartDate!)
                : 'Not set',
            onTap: () => _pickDate(isStart: true),
          ),
          const SizedBox(height: AppSizes.sm),

          _SectionLabel('Planned End (optional)'),
          _TapRow(
            label: 'End date',
            value: _plannedEndDate != null
                ? _dateFmt.format(_plannedEndDate!)
                : 'Not set',
            onTap: () => _pickDate(isStart: false),
          ),

          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }
}

// ── Form helpers ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.xs),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

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
