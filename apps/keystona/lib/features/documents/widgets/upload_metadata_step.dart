import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/document_upload_provider.dart';

/// Step 2 of the upload wizard — document name, expiration date, and notes.
///
/// The name field is pre-populated from the file's base name via
/// [DocumentUploadState.suggestedName].
class UploadMetadataStep extends ConsumerStatefulWidget {
  const UploadMetadataStep({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  ConsumerState<UploadMetadataStep> createState() =>
      _UploadMetadataStepState();
}

class _UploadMetadataStepState extends ConsumerState<UploadMetadataStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  DateTime? _expirationDate;

  @override
  void initState() {
    super.initState();
    final state = ref.read(documentUploadProvider);
    _nameController = TextEditingController(
      text: state.name.isNotEmpty ? state.name : state.suggestedName,
    );
    _notesController = TextEditingController(text: state.notes ?? '');
    _expirationDate = state.expirationDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Document details', style: AppTextStyles.h3),
        const SizedBox(height: AppSizes.xs),
        Text(
          'Name this document and add optional details.',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSizes.lg),
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // ── Name ─────────────────────────────────────────────────
                Text('Document name', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSizes.xs),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Home Insurance Policy 2025',
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a document name';
                    }
                    if (value.trim().length > 120) {
                      return 'Name must be 120 characters or fewer';
                    }
                    return null;
                  },
                  onChanged: (v) => ref
                      .read(documentUploadProvider.notifier)
                      .setName(v),
                ),

                const SizedBox(height: AppSizes.lg),

                // ── Expiration date ───────────────────────────────────────
                Text('Expiration date', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSizes.xs),
                Text(
                  'Optional — for warranties, insurance, permits.',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSizes.sm),
                _ExpirationDateField(
                  value: _expirationDate,
                  onChanged: (date) {
                    setState(() => _expirationDate = date);
                    ref
                        .read(documentUploadProvider.notifier)
                        .setExpirationDate(date);
                  },
                ),

                const SizedBox(height: AppSizes.lg),

                // ── Notes ─────────────────────────────────────────────────
                Text('Notes', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSizes.xs),
                Text(
                  'Optional — any context you want to remember.',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSizes.sm),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Add any notes…',
                    counterText: '',
                  ),
                  onChanged: (v) => ref
                      .read(documentUploadProvider.notifier)
                      .setNotes(v.trim().isEmpty ? null : v),
                ),
              ],
            ),
          ),
        ),

        // ── Actions ───────────────────────────────────────────────────────
        const SizedBox(height: AppSizes.md),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.deepNavy,
            minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
          ),
          child: Text(
            'Upload',
            style: AppTextStyles.button
                .copyWith(color: AppColors.textInverse),
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        TextButton(
          onPressed: widget.onBack,
          child: Text(
            'Back',
            style: AppTextStyles.button
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    // Persist final values before upload starts.
    final notifier =
        ref.read(documentUploadProvider.notifier);
    notifier.setName(_nameController.text.trim());
    notifier.setNotes(
      _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    notifier.setExpirationDate(_expirationDate);
    widget.onNext();
    notifier.upload();
  }
}

// ── Expiration date field ─────────────────────────────────────────────────────

class _ExpirationDateField extends StatelessWidget {
  const _ExpirationDateField({
    required this.value,
    required this.onChanged,
  });

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = value != null
        ? DateFormat('MMM d, yyyy').format(value!)
        : 'Select a date';

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: value != null
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
            ),
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? now.add(const Duration(days: 365)),
                firstDate: now,
                lastDate: DateTime(now.year + 30),
              );
              if (picked != null) onChanged(picked);
            },
          ),
        ),
        if (value != null) ...[
          const SizedBox(width: AppSizes.sm),
          IconButton(
            icon: const Icon(Icons.clear, color: AppColors.textSecondary),
            onPressed: () => onChanged(null),
          ),
        ],
      ],
    );
  }
}
