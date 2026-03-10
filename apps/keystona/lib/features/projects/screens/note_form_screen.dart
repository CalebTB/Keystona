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
import '../models/project_journal_note.dart';
import '../providers/project_journal_provider.dart';

typedef _PhaseOption = ({String id, String name});

/// Full-screen form for creating or editing a project journal note.
///
/// - Create mode: [existingNote] = null
/// - Edit mode: [existingNote] is provided
///
/// Pops with the note ID (String) on successful save.
class NoteFormScreen extends ConsumerStatefulWidget {
  const NoteFormScreen({
    super.key,
    required this.projectId,
    this.existingNote,
  });

  final String projectId;
  final ProjectJournalNote? existingNote;

  @override
  ConsumerState<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends ConsumerState<NoteFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  late DateTime _noteDate;
  String? _selectedPhaseId;
  List<_PhaseOption> _phases = [];
  bool _saving = false;

  bool get _isEditing => widget.existingNote != null;

  @override
  void initState() {
    super.initState();
    final n = widget.existingNote;
    _titleController = TextEditingController(text: n?.title ?? '');
    _contentController = TextEditingController(text: n?.content ?? '');
    _noteDate = n?.noteDate ?? DateTime.now();
    _selectedPhaseId = n?.phaseId;
    _loadPhases();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadPhases() async {
    try {
      final rows = await SupabaseService.client
          .from('project_phases')
          .select('id, name')
          .eq('project_id', widget.projectId)
          .order('sort_order', ascending: true);
      if (!mounted) return;
      setState(() {
        _phases = (rows as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map((r) => (id: r['id'] as String, name: r['name'] as String))
            .toList();
      });
    } catch (_) {
      // Phases are optional — silently ignore.
    }
  }

  Future<void> _pickDate() async {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      await _pickDateIOS();
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: _noteDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2050),
      );
      if (picked != null) setState(() => _noteDate = picked);
    }
  }

  Future<void> _pickDateIOS() async {
    DateTime picked = _noteDate;
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
                      setState(() => _noteDate = picked);
                      Navigator.of(context, rootNavigator: true).pop();
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _noteDate,
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

  Future<void> _pickPhaseIOS() async {
    final options = [(id: '', name: 'No phase'), ..._phases];
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Assign Phase'),
        actions: options
            .map((o) => CupertinoActionSheetAction(
                  onPressed: () {
                    setState(
                        () => _selectedPhaseId = o.id.isEmpty ? null : o.id);
                    Navigator.of(ctx, rootNavigator: true).pop();
                  },
                  child: Text(
                    o.name,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: (_selectedPhaseId == o.id ||
                              (o.id.isEmpty && _selectedPhaseId == null))
                          ? AppColors.goldAccent
                          : AppColors.textPrimary,
                      fontWeight:
                          (_selectedPhaseId == o.id ||
                                  (o.id.isEmpty && _selectedPhaseId == null))
                              ? FontWeight.w600
                              : FontWeight.normal,
                    ),
                  ),
                ))
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final notifier =
        ref.read(projectJournalProvider(widget.projectId).notifier);

    try {
      final title = _titleController.text.trim();
      final data = <String, dynamic>{
        'content': _contentController.text.trim(),
        'note_date': _noteDate.toIso8601String().split('T')[0],
        if (title.isNotEmpty) 'title': title,
        if (_selectedPhaseId != null) 'phase_id': _selectedPhaseId,
      };

      String id;
      if (_isEditing) {
        await notifier.updateNote(widget.existingNote!.id, data);
        id = widget.existingNote!.id;
      } else {
        id = await notifier.createNote(data);
      }

      if (!mounted) return;
      context.pop(id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarService.showError(
          context, 'Could not save note. Please try again.');
    }
  }

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
        middle: Text(_isEditing ? 'Edit Note' : 'New Note'),
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
        child: _FormBody(
          formKey: _formKey,
          titleController: _titleController,
          contentController: _contentController,
          noteDate: _noteDate,
          selectedPhaseId: _selectedPhaseId,
          phases: _phases,
          isIOS: true,
          onPickDate: _pickDate,
          onPickPhaseIOS: _pickPhaseIOS,
          onPhaseChanged: (v) => setState(
              () => _selectedPhaseId = (v == null || v.isEmpty) ? null : v),
        ),
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
        title: Text(_isEditing ? 'Edit Note' : 'New Note'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(AppSizes.sm),
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: _FormBody(
        formKey: _formKey,
        titleController: _titleController,
        contentController: _contentController,
        noteDate: _noteDate,
        selectedPhaseId: _selectedPhaseId,
        phases: _phases,
        isIOS: false,
        onPickDate: _pickDate,
        onPickPhaseIOS: _pickPhaseIOS,
        onPhaseChanged: (v) => setState(
            () => _selectedPhaseId = (v == null || v.isEmpty) ? null : v),
      ),
    );
  }
}

// ── Form body ─────────────────────────────────────────────────────────────────

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.formKey,
    required this.titleController,
    required this.contentController,
    required this.noteDate,
    required this.selectedPhaseId,
    required this.phases,
    required this.isIOS,
    required this.onPickDate,
    required this.onPickPhaseIOS,
    required this.onPhaseChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final DateTime noteDate;
  final String? selectedPhaseId;
  final List<_PhaseOption> phases;
  final bool isIOS;
  final VoidCallback onPickDate;
  final VoidCallback onPickPhaseIOS;
  final ValueChanged<String?> onPhaseChanged;

  static final _dateFmt = DateFormat('MMM d, yyyy');

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
      );

  String get _phaseLabelForSelected {
    if (selectedPhaseId == null) return 'No phase';
    try {
      return phases.firstWhere((p) => p.id == selectedPhaseId).name;
    } catch (_) {
      return 'No phase';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: AppPadding.screen,
        children: [
          _Label('Title (optional)'),
          TextFormField(
            controller: titleController,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 150,
            decoration: _decoration('e.g. Contractor meeting notes'),
          ),
          const SizedBox(height: AppSizes.sm),

          _Label('Note'),
          TextFormField(
            controller: contentController,
            maxLines: null,
            minLines: 3,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 5000,
            decoration: _decoration(
                'What happened, decisions made, quotes received…'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Note content is required'
                : null,
          ),
          const SizedBox(height: AppSizes.sm),

          _Label('Date'),
          _TapRow(
            label: 'Note date',
            value: _dateFmt.format(noteDate),
            onTap: onPickDate,
          ),
          const SizedBox(height: AppSizes.sm),

          if (phases.isNotEmpty) ...[
            _Label('Phase (optional)'),
            if (isIOS)
              _TapRow(
                label: 'Assign to phase',
                value: _phaseLabelForSelected,
                onTap: onPickPhaseIOS,
              )
            else
              DropdownButtonFormField<String>(
                initialValue: selectedPhaseId ?? '',
                decoration: _decoration(''),
                onChanged: onPhaseChanged,
                items: [
                  const DropdownMenuItem(value: '', child: Text('No phase')),
                  ...phases.map((p) =>
                      DropdownMenuItem(value: p.id, child: Text(p.name))),
                ],
              ),
            const SizedBox(height: AppSizes.sm),
          ],

          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
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
                  Text(label,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(value, style: AppTextStyles.bodyLarge),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.gray400, size: 20),
          ],
        ),
      ),
    );
  }
}
