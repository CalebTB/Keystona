import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/aurora_colors.dart';
import '../../../../core/theme/aurora_docs_b.dart';
import '../../../../core/theme/aurora_sizes.dart';
import '../../../../core/theme/aurora_typography.dart';
import '../../../../core/theme/aurora_scale.dart';
import '../../../../core/theme/aurora_spacing.dart';
import '../../../../core/widgets/aurora/aurora_form_section.dart';
import '../../../../core/widgets/aurora/aurora_text_field.dart';
import '../../../../services/providers/service_providers.dart';
import '../../../subscription/providers/subscription_provider.dart';
import '../../models/document_category.dart';
import '../../models/document_upload_state.dart';
import '../../providers/document_upload_provider.dart';
import '../../providers/documents_provider.dart';
import 'category_picker_sheet.dart';
import 'link_picker_sheet.dart';
import 'upload_add_file_tiles.dart';
import 'upload_category_field.dart';
import 'upload_expiry_section.dart';
import 'upload_file_card.dart';
import 'upload_link_field.dart';
import 'upload_renewal_banner.dart';
import 'upload_name_field.dart';
import 'upload_scan_banner.dart';
import 'upload_section_header.dart';
import 'upload_source_actions.dart';
import 'upload_tags_field.dart';

/// The scrolling form: file, name, category, expiry, details.
class UploadFormBody extends ConsumerStatefulWidget {
  const UploadFormBody({super.key, required this.categories});

  final List<DocumentCategory> categories;

  @override
  ConsumerState<UploadFormBody> createState() => _UploadFormBodyState();
}

class _UploadFormBodyState extends ConsumerState<UploadFormBody> {
  late final TextEditingController _name;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final state = ref.read(documentUploadProvider);
    _name = TextEditingController(text: state.name);
    _notes = TextEditingController(text: state.notes);
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  DocumentUploadNotifier get _notifier =>
      ref.read(documentUploadProvider.notifier);

  Future<void> _pickCategory(DocumentUploadState state) async {
    final chosen = await CategoryPickerSheet.show(
      context,
      categories: widget.categories,
      selectedId: state.categoryId,
    );
    if (chosen != null) _notifier.selectCategory(chosen);
  }

  Future<void> _pickLink(DocumentUploadState state) async {
    final choice = await LinkPickerSheet.show(context, current: state.link);
    if (choice != null) _notifier.setLink(choice.link);
  }

  Future<void> _pickDate(DocumentUploadState state) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final current = state.expirationDate;
    final first = current != null && current.isBefore(today) ? current : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? today,
      firstDate: first,
      lastDate: DateTime(
        today.year + AuroraUploadRules.expiryYearsAhead,
        today.month,
        today.day,
      ),
    );
    if (picked != null) _notifier.setExpirationDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    // Smart scan filled the name after the form opened: show it.
    ref.listen(documentUploadProvider.select((s) => s.name), (_, name) {
      if (_name.text != name) _name.text = name;
    });
    final state = ref.watch(documentUploadProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final a = context.aurora;
    final enabled = !state.isSaving;
    bool edged(UploadField f) => state.scanFilled.contains(f);
    final actions = UploadSourceActions(_notifier);

    return ListView(
      padding: a.symmetric(
        horizontal: AuroraSpacing.screenPadH,
        vertical: AuroraSpacing.space8,
      ),
      children: [
        if (state.renewal != null) ...[
          UploadRenewalBanner(documentName: state.renewal!.name),
          SizedBox(height: a.of(AuroraSpacing.formSection)),
        ],
        UploadSectionHeader(title: 'File', trailing: _planLabel(isPremium)),
        SizedBox(height: a.of(AuroraSpacing.space6)),
        if (state.hasFile) ...[
          UploadFileCard(
            label: state.fileLabel,
            mimeType: state.mimeType,
            sizeBytes: state.fileSizeBytes,
            preview: state.previewFile,
            onRemove: enabled
                ? () {
                    _notifier.removeFile();
                    _name.clear();
                  }
                : null,
          ),
          if (state.scanDetailCount > 0) ...[
            SizedBox(height: a.of(AuroraSpacing.space6)),
            UploadScanBanner(detailCount: state.scanDetailCount),
          ],
        ] else
          UploadAddFileTiles(
            onScan: () => actions.fromCamera(context, smart: isPremium),
            onPhotos: () => actions.fromLibrary(context),
            onFiles: () => actions.fromFiles(context),
          ),
        SizedBox(height: a.of(AuroraSpacing.formSection)),
        UploadNameField(
          controller: _name,
          onChanged: _notifier.setName,
          edged: edged(UploadField.name),
          enabled: enabled,
        ),
        SizedBox(height: a.of(AuroraSpacing.space7)),
        UploadCategoryField(
          name: state.categoryName,
          edged: edged(UploadField.category),
          onTap: enabled ? () => _pickCategory(state) : null,
        ),
        SizedBox(height: a.of(AuroraSpacing.space7)),
        UploadExpirySection(
          expires: state.expires,
          date: state.expirationDate,
          foundOnPage: edged(UploadField.expiration)
              ? state.expirationFoundOnPage
              : null,
          dateEdged: edged(UploadField.expiration),
          renewing: state.isRenewal,
          onToggle: enabled ? _notifier.setExpires : (_) {},
          onPickDate: () => enabled ? _pickDate(state) : null,
        ),
        AuroraFormSection(
          title: 'Details',
          isOptional: true,
          children: [
            UploadLinkField(
              link: state.link,
              edged: edged(UploadField.link),
              onTap: enabled ? () => _pickLink(state) : null,
            ),
            UploadTagsField(
              tags: state.tags,
              enabled: enabled,
              onAdd: _notifier.addTag,
              onRemove: _notifier.removeTag,
            ),
            AuroraTextField(
              label: 'Notes',
              controller: _notes,
              maxLines: AuroraTextField.textareaOpenLines,
              maxLength: AuroraUploadRules.maxNotesLength,
              hintText: 'Where the paper copy is, who to call for a claim…',
              readOnly: !enabled,
              onChanged: _notifier.setNotes,
            ),
          ],
        ),
        SizedBox(height: a.of(AuroraSpacing.space8)),
        const _PrivacyNote(),
      ],
    );
  }

  /// "13 OF 25 · FREE PLAN": where this document will put the user on the free
  /// plan. A renewal adds no document, so it shows nothing; neither does
  /// Premium, which has no limit.
  String? _planLabel(bool isPremium) {
    if (isPremium || ref.watch(documentUploadProvider).isRenewal) return null;
    final used = ref.watch(documentQuotaCountProvider).value;
    if (used == null) return null;
    return '${used + 1} OF $kFreeDocumentLimit · FREE PLAN';
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final a = context.aurora;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline,
          size: a.of(AuroraIconSizes.xs),
          color: AuroraColors.inkHelper,
        ),
        SizedBox(width: a.of(AuroraSpacing.space2)),
        Flexible(
          child: Text(
            'PRIVATE TO YOU · STORED ENCRYPTED',
            textAlign: TextAlign.center,
            style: AuroraType.helper,
          ),
        ),
      ],
    );
  }
}
