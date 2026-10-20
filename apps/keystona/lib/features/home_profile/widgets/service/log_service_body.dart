import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/aurora_home_b.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/aurora/aurora_button.dart';
import '../../../../core/widgets/aurora/aurora_chip.dart';
import '../../../../core/widgets/aurora/aurora_select_field.dart';
import '../../../../core/widgets/aurora/aurora_text_field.dart';
import '../../../../core/widgets/aurora/aurora_toggle_row.dart';
import '../../../../core/widgets/snackbar_service.dart';
import '../../forms/log_service_form.dart';
import '../../models/item_service_entry.dart';
import '../../systems_copy.dart';
import 'document_picker.dart';

/// The form inside the "Log a repair or service" sheet. [onSave] writes the
/// draft; the body closes the sheet with its own context once it succeeds.
class LogServiceBody extends StatefulWidget {
  const LogServiceBody({super.key, required this.onSave, this.editing});

  final Future<void> Function(ItemServiceDraft draft) onSave;
  final ItemServiceEntry? editing;

  @override
  State<LogServiceBody> createState() => _LogServiceBodyState();
}

class _LogServiceBodyState extends State<LogServiceBody> {
  late final LogServiceForm _form;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _form = LogServiceForm(editing: widget.editing);
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  static String _kindLabel(ServiceKind k) => switch (k) {
    ServiceKind.service => SystemsCopy.logKindService,
    ServiceKind.repair => SystemsCopy.logKindRepair,
    ServiceKind.installed => SystemsCopy.logKindInstalled,
    ServiceKind.purchased => SystemsCopy.logKindPurchased,
  };

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _form.date,
      firstDate: DateTime(AuroraHomeBSizes.firstInstallYear),
      lastDate: now,
    );
    if (picked != null) _form.setDate(picked);
  }

  Future<void> _pickDocument() async {
    final choice = await pickDocument(context);
    if (choice != null) _form.setDocument(choice.id, choice.name);
  }

  Future<void> _save() async {
    if (_saving || !_form.canSave) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(_form.toDraft());
      if (!mounted) return;
      // The sheet's own context: a root pop would close the page beneath it.
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      SnackbarService.showError(context, SystemsCopy.logFailed);
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    final gap = SizedBox(height: a.of(AuroraSpacing.space6));
    return Material(
      type: MaterialType.transparency,
      child: ListenableBuilder(
        listenable: _form,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_form.kinds.length > 1) ...[
              Wrap(
                spacing: a.of(AuroraSpacing.space3),
                runSpacing: a.of(AuroraSpacing.space3),
                children: [
                  for (final k in _form.kinds)
                    FilterPill(
                      label: _kindLabel(k),
                      selected: k == _form.kind,
                      onTap: () => _form.setKind(k),
                    ),
                ],
              ),
              gap,
            ],
            AuroraTextField(
              label: SystemsCopy.logWhat,
              controller: _form.title,
              required: true,
              hintText: SystemsCopy.logWhatHint,
              maxLength: AuroraHomeBSizes.nameMaxLength,
            ),
            gap,
            AuroraSelectField(
              label: SystemsCopy.logDate,
              value: DateFormat.yMMMd().format(_form.date),
              onTap: _pickDate,
            ),
            gap,
            AuroraTextField(
              label: SystemsCopy.logProvider,
              controller: _form.provider,
              hintText: SystemsCopy.logProviderHint,
              maxLength: AuroraHomeBSizes.fieldMaxLength,
            ),
            gap,
            AuroraTextField(
              label: SystemsCopy.logCost,
              controller: _form.cost,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              helperText: _form.costInvalid ? SystemsCopy.logCostInvalid : null,
            ),
            gap,
            AuroraToggleRow(
              label: SystemsCopy.logWarranty,
              helperText: SystemsCopy.logWarrantyHelper,
              value: _form.underWarranty,
              onChanged: _form.setUnderWarranty,
            ),
            gap,
            AuroraTextField(
              label: SystemsCopy.logNote,
              controller: _form.note,
              maxLines: 4,
              maxLength: AuroraHomeBSizes.noteMaxLength,
            ),
            gap,
            AuroraSelectField(
              label: SystemsCopy.logDocument,
              value: _form.documentId == null
                  ? null
                  : (_form.documentName ?? SystemsCopy.warrantyDefaultTitle),
              placeholder: SystemsCopy.warrantyDocNone,
              onTap: _pickDocument,
            ),
            SizedBox(height: a.of(AuroraSpacing.space9)),
            PrimaryButton(
              label: SystemsCopy.logSave,
              loading: _saving,
              onPressed: _form.canSave ? _save : null,
              expand: true,
            ),
          ],
        ),
      ),
    );
  }
}
