import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/aurora/aurora.dart';
import '../../../core/widgets/empty_state.dart';
import '../../documents/providers/documents_provider.dart';
import '../providers/task_detail_provider.dart';

/// Detailed task completion form.
///
/// Route: `/maintenance/complete/:taskId`
///
/// Collects date, completed-by, contractor info, costs, time spent, notes,
/// photos (uploaded to `completion-photos` bucket), and linked receipts.
///
/// On save: calls [TaskDetailNotifier.completeTaskDetailed], then pops with
/// the created completion ID so [TaskDetailScreen] can show an undo snackbar.
class TaskCompletionFormScreen extends ConsumerStatefulWidget {
  const TaskCompletionFormScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<TaskCompletionFormScreen> createState() =>
      _TaskCompletionFormScreenState();
}

class _TaskCompletionFormScreenState
    extends ConsumerState<TaskCompletionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // ── Form state ─────────────────────────────────────────────────────────────

  DateTime _completedDate = DateTime.now();
  String _completedBy = 'diy'; // 'diy' | 'contractor'

  // Contractor
  final _contractorNameController = TextEditingController();
  final _contractorCompanyController = TextEditingController();
  final _contractorPhoneController = TextEditingController();

  // Costs
  final _serviceCostController = TextEditingController();
  final _materialsCostController = TextEditingController();

  // Time / notes
  final _timeMinutesController = TextEditingController();
  final _notesController = TextEditingController();

  // Photos & receipts
  final List<XFile> _photos = [];
  final List<String> _linkedDocumentIds = [];

  bool _isSaving = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _contractorNameController.dispose();
    _contractorCompanyController.dispose();
    _contractorPhoneController.dispose();
    _serviceCostController.dispose();
    _materialsCostController.dispose();
    _timeMinutesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _pickDate(BuildContext context) async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIOS) {
      await showCupertinoModalPopup<void>(
        context: context,
        builder: (_) => Container(
          height: 280,
          color: AuroraColors.paper,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: _completedDate,
            maximumDate: DateTime.now(),
            onDateTimeChanged: (d) => setState(() => _completedDate = d),
          ),
        ),
      );
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: _completedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );
      if (picked != null) setState(() => _completedDate = picked);
    }
  }

  Future<void> _pickPhotos() async {
    final images = await _picker.pickMultiImage(imageQuality: 85);
    if (images.isEmpty) return;
    // Validate: only jpg/png/heic/webp, max 10MB each.
    final valid = <XFile>[];
    for (final img in images) {
      final bytes = await img.readAsBytes();
      if (bytes.length > 10 * 1024 * 1024) continue; // skip > 10MB
      final ext = img.name.split('.').last.toLowerCase();
      if (!{'jpg', 'jpeg', 'png', 'heic', 'webp'}.contains(ext)) continue;
      valid.add(img);
    }
    setState(() => _photos.addAll(valid));
  }

  Future<void> _linkReceipts(BuildContext context) async {
    final selected = await _ReceiptPickerSheet.show(
      context,
      ref: ref,
      alreadyLinked: _linkedDocumentIds,
    );
    if (selected != null) {
      setState(() {
        _linkedDocumentIds
          ..clear()
          ..addAll(selected);
      });
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final dateStr = _completedDate.toIso8601String().split('T')[0];

    final formData = <String, dynamic>{
      'completed_date': dateStr,
      'completed_by': _completedBy,
      if (_completedBy == 'contractor') ...{
        if (_contractorNameController.text.trim().isNotEmpty)
          'contractor_name': _contractorNameController.text.trim(),
        if (_contractorCompanyController.text.trim().isNotEmpty)
          'contractor_company': _contractorCompanyController.text.trim(),
        if (_contractorPhoneController.text.trim().isNotEmpty)
          'contractor_phone': _contractorPhoneController.text.trim(),
      },
      if (_serviceCostController.text.trim().isNotEmpty)
        'service_cost':
            double.tryParse(_serviceCostController.text.trim()),
      if (_materialsCostController.text.trim().isNotEmpty)
        'materials_cost':
            double.tryParse(_materialsCostController.text.trim()),
      if (_timeMinutesController.text.trim().isNotEmpty)
        'time_spent_minutes':
            int.tryParse(_timeMinutesController.text.trim()),
      if (_notesController.text.trim().isNotEmpty)
        'notes': _notesController.text.trim(),
      if (_linkedDocumentIds.isNotEmpty)
        'linked_document_ids': _linkedDocumentIds,
    };

    String? completionId;
    try {
      completionId = await ref
          .read(taskDetailProvider(widget.taskId).notifier)
          .completeTaskDetailed(formData, _photos);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text("Couldn't save completion. Try again."),
            backgroundColor: AuroraColors.coral,
            behavior: SnackBarBehavior.floating,
          ),
        );
      setState(() => _isSaving = false);
      return;
    }

    if (!mounted) return;
    // Pop with the completion ID so the caller can show the undo snackbar.
    context.pop(completionId);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return isIOS ? _buildIOS(context) : _buildAndroid(context);
  }

  Widget _buildIOS(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        previousPageTitle: 'Task',
        middle: Text('Complete Task'),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: _FormBody(
                  completedDate: _completedDate,
                  completedBy: _completedBy,
                  contractorNameController: _contractorNameController,
                  contractorCompanyController: _contractorCompanyController,
                  contractorPhoneController: _contractorPhoneController,
                  serviceCostController: _serviceCostController,
                  materialsCostController: _materialsCostController,
                  timeMinutesController: _timeMinutesController,
                  notesController: _notesController,
                  photos: _photos,
                  linkedDocumentIds: _linkedDocumentIds,
                  isIOS: true,
                  onPickDate: () => _pickDate(context),
                  onToggleCompletedBy: (v) => setState(() => _completedBy = v),
                  onPickPhotos: _pickPhotos,
                  onRemovePhoto: (i) => setState(() => _photos.removeAt(i)),
                  onLinkReceipts: () => _linkReceipts(context),
                ),
              ),
            ),
            _CompletionBottomBar(saving: _isSaving, onSave: _save, onCancel: () => context.pop()),
          ],
        ),
      ),
    );
  }

  Widget _buildAndroid(BuildContext context) {
    return Scaffold(
      backgroundColor: AuroraColors.paper,
      appBar: AppBar(
        title: Text('Complete Task', style: AuroraType.h3),
        backgroundColor: AuroraColors.paper,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: _FormBody(
                completedDate: _completedDate,
                completedBy: _completedBy,
                contractorNameController: _contractorNameController,
                contractorCompanyController: _contractorCompanyController,
                contractorPhoneController: _contractorPhoneController,
                serviceCostController: _serviceCostController,
                materialsCostController: _materialsCostController,
                timeMinutesController: _timeMinutesController,
                notesController: _notesController,
                photos: _photos,
                linkedDocumentIds: _linkedDocumentIds,
                isIOS: false,
                onPickDate: () => _pickDate(context),
                onToggleCompletedBy: (v) => setState(() => _completedBy = v),
                onPickPhotos: _pickPhotos,
                onRemovePhoto: (i) => setState(() => _photos.removeAt(i)),
                onLinkReceipts: () => _linkReceipts(context),
              ),
            ),
          ),
          _CompletionBottomBar(saving: _isSaving, onSave: _save, onCancel: () => context.pop()),
        ],
      ),
    );
  }
}

// ── Shared form body ──────────────────────────────────────────────────────────

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.completedDate,
    required this.completedBy,
    required this.contractorNameController,
    required this.contractorCompanyController,
    required this.contractorPhoneController,
    required this.serviceCostController,
    required this.materialsCostController,
    required this.timeMinutesController,
    required this.notesController,
    required this.photos,
    required this.linkedDocumentIds,
    required this.isIOS,
    required this.onPickDate,
    required this.onToggleCompletedBy,
    required this.onPickPhotos,
    required this.onRemovePhoto,
    required this.onLinkReceipts,
  });

  final DateTime completedDate;
  final String completedBy;
  final TextEditingController contractorNameController;
  final TextEditingController contractorCompanyController;
  final TextEditingController contractorPhoneController;
  final TextEditingController serviceCostController;
  final TextEditingController materialsCostController;
  final TextEditingController timeMinutesController;
  final TextEditingController notesController;
  final List<XFile> photos;
  final List<String> linkedDocumentIds;
  final bool isIOS;
  final VoidCallback onPickDate;
  final void Function(String) onToggleCompletedBy;
  final VoidCallback onPickPhotos;
  final void Function(int) onRemovePhoto;
  final VoidCallback onLinkReceipts;

  @override
  Widget build(BuildContext context) {
    final showContractor = completedBy == 'contractor';

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AuroraSpacing.screenPadH,
        right: AuroraSpacing.screenPadH,
        top: AuroraSpacing.space5,
        bottom: AuroraSpacing.screenPadH +
            MediaQuery.of(context).padding.bottom +
            AuroraSpacing.space8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Date completed ──────────────────────────────────────────────────
          _SectionLabel(text: 'Date Completed'),
          const SizedBox(height: AuroraSpacing.space1),
          _TappableRow(
            label: DateFormat('MMMM d, y').format(completedDate),
            icon: Icons.calendar_today_outlined,
            onTap: onPickDate,
          ),
          const SizedBox(height: AuroraSpacing.space7),
          const _Divider(),
          const SizedBox(height: AuroraSpacing.space7),

          // ── Completed by ────────────────────────────────────────────────────
          _SectionLabel(text: 'Completed By'),
          const SizedBox(height: AuroraSpacing.space3),
          _SegmentedToggle(
            selected: completedBy,
            options: const {'diy': 'DIY', 'contractor': 'Contractor'},
            onChanged: onToggleCompletedBy,
          ),
          const SizedBox(height: AuroraSpacing.space7),

          // ── Contractor info (conditional) ───────────────────────────────────
          if (showContractor) ...[
            const _Divider(),
            const SizedBox(height: AuroraSpacing.space7),
            _SectionLabel(text: 'Contractor Info'),
            const SizedBox(height: AuroraSpacing.space3),
            _FormField(
              controller: contractorNameController,
              label: 'Name',
              maxLength: 200,
            ),
            const SizedBox(height: AuroraSpacing.space3),
            _FormField(
              controller: contractorCompanyController,
              label: 'Company (optional)',
              maxLength: 200,
            ),
            const SizedBox(height: AuroraSpacing.space3),
            _FormField(
              controller: contractorPhoneController,
              label: 'Phone (optional)',
              keyboardType: TextInputType.phone,
              maxLength: 20,
            ),
            const SizedBox(height: AuroraSpacing.space7),
          ],

          const _Divider(),
          const SizedBox(height: AuroraSpacing.space7),

          // ── Costs ───────────────────────────────────────────────────────────
          _SectionLabel(text: 'Cost (optional)'),
          const SizedBox(height: AuroraSpacing.space3),
          Row(
            children: [
              Expanded(
                child: _FormField(
                  controller: serviceCostController,
                  label: 'Service cost',
                  prefix: '\$',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: _validateCost,
                ),
              ),
              const SizedBox(width: AuroraSpacing.space3),
              Expanded(
                child: _FormField(
                  controller: materialsCostController,
                  label: 'Materials cost',
                  prefix: '\$',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: _validateCost,
                ),
              ),
            ],
          ),
          const SizedBox(height: AuroraSpacing.space7),
          const _Divider(),
          const SizedBox(height: AuroraSpacing.space7),

          // ── Time spent ──────────────────────────────────────────────────────
          _SectionLabel(text: 'Time Spent (optional)'),
          const SizedBox(height: AuroraSpacing.space3),
          _FormField(
            controller: timeMinutesController,
            label: 'Minutes',
            keyboardType: TextInputType.number,
            validator: _validateMinutes,
          ),
          const SizedBox(height: AuroraSpacing.space7),
          const _Divider(),
          const SizedBox(height: AuroraSpacing.space7),

          // ── Notes ───────────────────────────────────────────────────────────
          _SectionLabel(text: 'Notes (optional)'),
          const SizedBox(height: AuroraSpacing.space3),
          _FormField(
            controller: notesController,
            label: 'Add notes…',
            maxLines: 4,
            maxLength: 5000,
          ),
          const SizedBox(height: AuroraSpacing.space7),
          const _Divider(),
          const SizedBox(height: AuroraSpacing.space7),

          // ── Photos ──────────────────────────────────────────────────────────
          _SectionLabel(text: 'Photos (optional)'),
          const SizedBox(height: AuroraSpacing.space3),
          if (photos.isNotEmpty)
            _PhotoGrid(photos: photos, onRemove: onRemovePhoto),
          const SizedBox(height: AuroraSpacing.space3),
          SecondaryButton(
            label: photos.isEmpty ? 'Add Photos' : 'Add More Photos',
            onPressed: onPickPhotos,
            expand: true,
          ),
          const SizedBox(height: AuroraSpacing.space7),
          const _Divider(),
          const SizedBox(height: AuroraSpacing.space7),

          // ── Linked receipts ─────────────────────────────────────────────────
          _SectionLabel(text: 'Link Receipt (optional)'),
          const SizedBox(height: AuroraSpacing.space3),
          if (linkedDocumentIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AuroraSpacing.space3),
              child: Text(
                '${linkedDocumentIds.length} receipt${linkedDocumentIds.length == 1 ? '' : 's'} linked',
                style: AuroraType.bodySm.copyWith(
                  color: AuroraColors.lime,
                ),
              ),
            ),
          SecondaryButton(
            label: linkedDocumentIds.isEmpty
                ? 'Add Receipt'
                : 'Change Linked Receipts',
            onPressed: onLinkReceipts,
            expand: true,
          ),
        ],
      ),
    );
  }

  String? _validateCost(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final d = double.tryParse(value.trim());
    if (d == null) return 'Enter a valid amount';
    if (d < 0) return 'Must be 0 or more';
    if (d > 10000000) return 'Amount too large';
    return null;
  }

  String? _validateMinutes(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final n = int.tryParse(value.trim());
    if (n == null) return 'Enter a whole number';
    if (n < 0) return 'Must be 0 or more';
    return null;
  }
}

// ── Photo grid ─────────────────────────────────────────────────────────────────

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({required this.photos, required this.onRemove});

  final List<XFile> photos;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AuroraSpacing.space3,
      runSpacing: AuroraSpacing.space3,
      children: [
        for (int i = 0; i < photos.length; i++)
          _PhotoThumbnail(photo: photos[i], onRemove: () => onRemove(i)),
      ],
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.photo, required this.onRemove});

  final XFile photo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: AuroraRadius.sm,
          child: Image.file(
            File(photo.path),
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 80,
              height: 80,
              color: AuroraColors.inkBorder,
              child: const Icon(Icons.image_outlined, color: AuroraColors.inkTertiary),
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: AuroraColors.coral,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 12, color: AuroraColors.paper),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Receipt picker sheet ───────────────────────────────────────────────────────

/// Bottom sheet for picking linked receipts from the Document Vault.
///
/// Returns the updated list of selected document IDs, or null if cancelled.
class _ReceiptPickerSheet extends ConsumerStatefulWidget {
  const _ReceiptPickerSheet({required this.alreadyLinked});

  final List<String> alreadyLinked;

  static Future<List<String>?> show(
    BuildContext context, {
    required WidgetRef ref,
    required List<String> alreadyLinked,
  }) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIOS) {
      return showCupertinoModalPopup<List<String>>(
        context: context,
        builder: (_) => Material(
          type: MaterialType.transparency,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: _ReceiptPickerSheet(alreadyLinked: alreadyLinked),
          ),
        ),
      );
    }
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AuroraColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: AuroraSheet.topRadius(context),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) =>
            _ReceiptPickerSheet(alreadyLinked: alreadyLinked),
      ),
    );
  }

  @override
  ConsumerState<_ReceiptPickerSheet> createState() =>
      _ReceiptPickerSheetState();
}

class _ReceiptPickerSheetState extends ConsumerState<_ReceiptPickerSheet> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.alreadyLinked);
  }

  void _confirm() {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIOS) {
      Navigator.of(context, rootNavigator: true).pop(_selected);
    } else {
      context.pop(_selected);
    }
  }

  void _cancel() {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIOS) {
      Navigator.of(context, rootNavigator: true).pop();
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(documentsProvider);

    return Container(
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        borderRadius: AuroraSheet.topRadius(context),
      ),
      child: Column(
        children: [
          // Handle + header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AuroraSpacing.screenPadH,
              AuroraSpacing.space5,
              AuroraSpacing.screenPadH,
              0,
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AuroraColors.inkBorder,
                      borderRadius: AuroraRadius.xs,
                    ),
                  ),
                ),
                const SizedBox(height: AuroraSpacing.space5),
                Row(
                  children: [
                    Expanded(
                      child: Text('Link Receipt', style: AuroraType.h3),
                    ),
                    SecondaryButton(
                      label: 'Cancel',
                      onPressed: _cancel,
                    ),
                    const SizedBox(width: AuroraSpacing.space3),
                    SaveButton(
                      label: 'Done',
                      onPressed: _confirm,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Document list
          Expanded(
            child: docsAsync.when(
              loading: () =>
                  const Center(child: CupertinoActivityIndicator(color: AuroraColors.ink)),
              error: (_, _) => Center(
                child: Text(
                  'Couldn\'t load documents.',
                  style: AuroraType.body.copyWith(
                    color: AuroraColors.inkSecondary,
                  ),
                ),
              ),
              data: (docs) {
                if (docs.isEmpty) {
                  return const Center(
                    child: EmptyState(
                      icon: CupertinoIcons.folder,
                      title: 'No documents yet',
                      subtitle: 'Upload documents to your vault to link them as receipts.',
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 16),
                  itemBuilder: (_, i) {
                    final doc = docs[i];
                    final isSelected = _selected.contains(doc.id);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (_) {
                        setState(() {
                          if (isSelected) {
                            _selected.remove(doc.id);
                          } else {
                            _selected.add(doc.id);
                          }
                        });
                      },
                      title: Text(
                        doc.name,
                        style: AuroraType.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: doc.notes != null && doc.notes!.isNotEmpty
                          ? Text(
                              doc.notes!,
                              style: AuroraType.bodySm.copyWith(
                                color: AuroraColors.inkSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      activeColor: AuroraColors.ink,
                      controlAffinity: ListTileControlAffinity.trailing,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small form widgets ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AuroraColors.cobalt,
            borderRadius: AuroraRadius.xs,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text.toUpperCase(),
          style: AuroraType.label.copyWith(
            color: AuroraColors.inkSecondary,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AuroraColors.inkBorder);
  }
}

class _TappableRow extends StatelessWidget {
  const _TappableRow({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AuroraSpacing.space5,
          vertical: AuroraSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: AuroraColors.butter,
          borderRadius: AuroraRadius.md,
          border: Border.all(color: AuroraColors.inkBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AuroraColors.inkSecondary),
            const SizedBox(width: AuroraSpacing.space3),
            Expanded(
              child: Text(label, style: AuroraType.body),
            ),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AuroraColors.inkSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedToggle extends StatelessWidget {
  const _SegmentedToggle({
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  final String selected;
  final Map<String, String> options;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.entries.map((entry) {
        final isSelected = selected == entry.key;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(
                right: entry.key != options.keys.last ? AuroraSpacing.space1 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: AuroraSpacing.space3),
              decoration: BoxDecoration(
                color: isSelected ? AuroraColors.ink : AuroraColors.paper,
                borderRadius: AuroraRadius.md,
                border: Border.all(
                  color: isSelected ? AuroraColors.ink : AuroraColors.inkBorder,
                ),
              ),
              child: Center(
                child: Text(
                  entry.value,
                  style: AuroraType.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AuroraColors.paper
                        : AuroraColors.ink,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    this.prefix,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? prefix;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      style: AuroraType.body,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AuroraType.label.copyWith(
          color: AuroraColors.inkSecondary,
        ),
        prefixText: prefix,
        prefixStyle: AuroraType.body,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: AuroraRadius.md,
          borderSide: const BorderSide(color: AuroraColors.inkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AuroraRadius.md,
          borderSide: const BorderSide(color: AuroraColors.inkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AuroraRadius.md,
          borderSide: const BorderSide(color: AuroraColors.coral, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AuroraRadius.md,
          borderSide: const BorderSide(color: AuroraColors.coral),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AuroraRadius.md,
          borderSide: const BorderSide(color: AuroraColors.coral),
        ),
        filled: true,
        fillColor: AuroraColors.butter,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AuroraSpacing.space5,
          vertical: AuroraSpacing.space3,
        ),
      ),
    );
  }
}

// ── Completion form bottom action bar ─────────────────────────────────────────

/// Sticky bottom bar with SaveButton (cobalt) and SecondaryButton (cancel).
class _CompletionBottomBar extends StatelessWidget {
  const _CompletionBottomBar({
    required this.saving,
    required this.onSave,
    required this.onCancel,
  });

  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AuroraSpacing.screenPadH,
        AuroraSpacing.space4,
        AuroraSpacing.screenPadH,
        AuroraSpacing.space4 + bottomPad,
      ),
      decoration: BoxDecoration(
        color: AuroraColors.paper,
        border: Border(
          top: BorderSide(color: AuroraColors.inkBorder),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SecondaryButton(
              label: 'Cancel',
              expand: true,
              onPressed: saving ? null : onCancel,
            ),
          ),
          const SizedBox(width: AuroraSpacing.space3),
          Expanded(
            flex: 2,
            child: SaveButton(
              label: 'Save Completion',
              loading: saving,
              expand: true,
              onPressed: saving ? null : onSave,
            ),
          ),
        ],
      ),
    );
  }
}
