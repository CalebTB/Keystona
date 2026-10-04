import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/theme/aurora_spacing.dart';

import '../models/project_document_link.dart';
import '../providers/project_documents_provider.dart';
import '../../../core/widgets/aurora/aurora_sheet.dart';

/// Shows a platform-adaptive picker sheet for linking a document to a project.
///
/// Returns `({String documentId, String linkType})` or `null` if cancelled.
Future<({String documentId, String linkType})?> showDocumentLinkPickerSheet(
    BuildContext context) async {
  final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
  if (isIOS) {
    return showCupertinoModalPopup<({String documentId, String linkType})?>(
      context: context,
      builder: (_) => const Material(
        type: MaterialType.transparency,
        child: _DocumentLinkPickerSheet(),
      ),
    );
  }
  return showModalBottomSheet<({String documentId, String linkType})?>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _DocumentLinkPickerSheet(),
  );
}

class _DocumentLinkPickerSheet extends ConsumerStatefulWidget {
  const _DocumentLinkPickerSheet();

  @override
  ConsumerState<_DocumentLinkPickerSheet> createState() =>
      _DocumentLinkPickerSheetState();
}

class _DocumentLinkPickerSheetState
    extends ConsumerState<_DocumentLinkPickerSheet> {
  String? _selectedDocId;
  String _linkType = 'general';

  @override
  Widget build(BuildContext context) {
    final asyncDocs = ref.watch(propertyDocumentPickerListProvider);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AuroraSheet.topRadius(context),
        ),
        padding: EdgeInsets.all(AuroraSpacing.screenPadH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle.
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AuroraSpacing.space7),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0DFEA),
                  borderRadius:
                      BorderRadius.circular(999.0),
                ),
              ),
            ),

            Text('Link a Document', style: AuroraType.h3),
            const SizedBox(height: AuroraSpacing.space3),
            Text(
              'Select a document from your vault:',
              style: AuroraType.bodySm
                  .copyWith(color: AuroraColors.inkSecondary),
            ),
            const SizedBox(height: AuroraSpacing.space3),

            // Document list.
            Flexible(
              child: asyncDocs.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, _) => Center(
                  child: Text(
                    'Could not load documents.',
                    style: AuroraType.bodySm
                        .copyWith(color: AuroraColors.coral),
                  ),
                ),
                data: (docs) {
                  if (docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AuroraSpacing.space9),
                        child: Text(
                          'No documents in your vault yet.',
                          style: AuroraType.bodySm.copyWith(
                              color: AuroraColors.inkSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: docs.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final d = docs[i];
                      final isSelected = _selectedDocId == d.id;
                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        selectedTileColor:
                            AuroraColors.ink.withValues(alpha: 0.05),
                        leading: Icon(
                          Icons.description_outlined,
                          color: isSelected
                              ? AuroraColors.ink
                              : AuroraColors.inkTertiary,
                        ),
                        title: Text(d.name,
                            style: AuroraType.body),
                        subtitle: d.typeName != null
                            ? Text(d.typeName!,
                                style: AuroraType.bodySm.copyWith(
                                    color: AuroraColors.inkSecondary))
                            : null,
                        trailing: isSelected
                            ? const Icon(Icons.check_circle,
                                color: AuroraColors.ink)
                            : null,
                        onTap: () =>
                            setState(() => _selectedDocId = d.id),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: AuroraSpacing.space7),

            // Link type chips.
            Text(
              'Link type:',
              style: AuroraType.bodySm
                  .copyWith(color: AuroraColors.inkSecondary),
            ),
            const SizedBox(height: AuroraSpacing.space1),
            Wrap(
              spacing: AuroraSpacing.space1,
              runSpacing: AuroraSpacing.space1,
              children: DocumentLinkTypes.all.map((t) {
                final selected = _linkType == t.value;
                return GestureDetector(
                  onTap: () => setState(() => _linkType = t.value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AuroraSpacing.space3 + 2,
                        vertical: AuroraSpacing.space1),
                    decoration: BoxDecoration(
                      color:
                          selected ? AuroraColors.ink : AuroraColors.paper,
                      borderRadius:
                          BorderRadius.circular(999.0),
                      border: Border.all(
                        color: selected
                            ? AuroraColors.ink
                            : AuroraColors.inkBorder,
                      ),
                    ),
                    child: Text(
                      t.label,
                      style: AuroraType.label.copyWith(
                        color: selected
                            ? Colors.white
                            : AuroraColors.ink,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AuroraSpacing.space9),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedDocId == null
                    ? null
                    : () => Navigator.of(context, rootNavigator: true).pop((
                          documentId: _selectedDocId!,
                          linkType: _linkType,
                        )),
                style: FilledButton.styleFrom(
                  backgroundColor: AuroraColors.coral,
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                child: const Text('Link Document'),
              ),
            ),
            const SizedBox(height: AuroraSpacing.space7),
          ],
        ),
      ),
    );
  }
}
