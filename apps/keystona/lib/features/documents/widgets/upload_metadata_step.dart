import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/widgets/aurora/aurora.dart';
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
        // Section eyebrow — cobalt dot + label (form is an action surface).
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 6),
              decoration: const BoxDecoration(
                color: AuroraColors.cobalt,
                shape: BoxShape.circle,
              ),
            ),
            Text(
              'DOCUMENT DETAILS',
              style: AuroraType.label.copyWith(
                color: AuroraColors.inkSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AuroraSpacing.space5),
        Text(
          'Name this document and add optional details.',
          style: AuroraType.body.copyWith(color: AuroraColors.inkSecondary),
        ),
        const SizedBox(height: AuroraSpacing.space7),
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // ── Name (required) ───────────────────────────────────────
                RichText(
                  text: TextSpan(
                    style: AuroraType.label.copyWith(
                      color: AuroraColors.inkSecondary,
                    ),
                    children: [
                      const TextSpan(text: 'DOCUMENT NAME'),
                      TextSpan(
                        text: ' *',
                        style: AuroraType.label.copyWith(
                          color: AuroraColors.coral,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AuroraSpacing.space3),
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

                const SizedBox(height: AuroraSpacing.space7),

                // ── Expiration date (optional) ────────────────────────────
                Text(
                  'EXPIRATION DATE',
                  style: AuroraType.label.copyWith(
                    color: AuroraColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: AuroraSpacing.space3),
                Text(
                  'Optional — for warranties, insurance, permits.',
                  style: AuroraType.bodySm.copyWith(
                    color: AuroraColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: AuroraSpacing.space3),
                _ExpirationDateField(
                  value: _expirationDate,
                  onChanged: (date) {
                    setState(() => _expirationDate = date);
                    ref
                        .read(documentUploadProvider.notifier)
                        .setExpirationDate(date);
                  },
                ),

                const SizedBox(height: AuroraSpacing.space7),

                // ── Notes (optional) ──────────────────────────────────────
                Text(
                  'NOTES',
                  style: AuroraType.label.copyWith(
                    color: AuroraColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: AuroraSpacing.space3),
                Text(
                  'Optional — any context you want to remember.',
                  style: AuroraType.bodySm.copyWith(
                    color: AuroraColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: AuroraSpacing.space3),
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

        // ── Actions — SaveButton (cobalt) + SecondaryButton (cancel/back) ─
        const SizedBox(height: AuroraSpacing.space5),
        SaveButton(
          label: 'Upload Document',
          onPressed: _submit,
          expand: true,
        ),
        const SizedBox(height: AuroraSpacing.space3),
        SecondaryButton(
          label: 'Back',
          onPressed: widget.onBack,
          expand: true,
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
              style: AuroraType.body.copyWith(
                color: value != null
                    ? AuroraColors.ink
                    : AuroraColors.inkSecondary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(
                horizontal: AuroraSpacing.space5,
                vertical: AuroraSpacing.space3,
              ),
              side: const BorderSide(color: AuroraColors.inkBorder),
              shape: const RoundedRectangleBorder(
                borderRadius: AuroraRadius.sm,
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
          const SizedBox(width: AuroraSpacing.space3),
          IconButton(
            icon: Icon(Icons.clear, color: AuroraColors.inkSecondary),
            onPressed: () => onChanged(null),
          ),
        ],
      ],
    );
  }
}
