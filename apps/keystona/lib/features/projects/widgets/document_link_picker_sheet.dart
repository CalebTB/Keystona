import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/project_document_link.dart';
import '../providers/project_documents_provider.dart';

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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: AppPadding.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle.
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusFull),
                ),
              ),
            ),

            Text('Link a Document', style: AppTextStyles.h3),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Select a document from your vault:',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSizes.sm),

            // Document list.
            Flexible(
              child: asyncDocs.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: Text(
                    'Could not load documents.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.error),
                  ),
                ),
                data: (docs) {
                  if (docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.lg),
                        child: Text(
                          'No documents in your vault yet.',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary),
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
                            AppColors.deepNavy.withValues(alpha: 0.05),
                        leading: Icon(
                          Icons.description_outlined,
                          color: isSelected
                              ? AppColors.deepNavy
                              : AppColors.gray400,
                        ),
                        title: Text(d.name,
                            style: AppTextStyles.bodyMedium),
                        subtitle: d.typeName != null
                            ? Text(d.typeName!,
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary))
                            : null,
                        trailing: isSelected
                            ? const Icon(Icons.check_circle,
                                color: AppColors.deepNavy)
                            : null,
                        onTap: () =>
                            setState(() => _selectedDocId = d.id),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: AppSizes.md),

            // Link type chips.
            Text(
              'Link type:',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSizes.xs),
            Wrap(
              spacing: AppSizes.xs,
              runSpacing: AppSizes.xs,
              children: DocumentLinkTypes.all.map((t) {
                final selected = _linkType == t.value;
                return GestureDetector(
                  onTap: () => setState(() => _linkType = t.value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm + 2,
                        vertical: AppSizes.xs),
                    decoration: BoxDecoration(
                      color:
                          selected ? AppColors.deepNavy : AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                      border: Border.all(
                        color: selected
                            ? AppColors.deepNavy
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      t.label,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: selected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSizes.lg),

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
                  backgroundColor: AppColors.deepNavy,
                  padding: AppPadding.button,
                ),
                child: const Text('Link Document'),
              ),
            ),
            const SizedBox(height: AppSizes.md),
          ],
        ),
      ),
    );
  }
}
