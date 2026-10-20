import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_scale.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../../../core/widgets/upgrade_sheet.dart';
import '../docs_copy.dart';
import '../models/document_category.dart';
import '../models/document_upload_state.dart';
import '../models/renewal_source.dart';
import '../providers/document_categories_provider.dart';
import '../providers/document_flow.dart';
import '../providers/document_renewal_provider.dart';
import '../providers/document_upload_provider.dart';
import '../widgets/upload/upload_form_body.dart';
import '../widgets/upload/upload_form_skeleton.dart';
import '../widgets/upload/upload_header.dart';
import '../widgets/upload/upload_progress_bar.dart';

/// New document (kit: AddDocument): the file, its details, and Save with
/// upload progress.
///
/// Opened once a file has been picked from the add-from sheet; opened with no
/// file (e.g. from the onboarding checklist) it shows Scan, Photos and Files.
///
/// With [renewDocumentId] it renews that document in place: the form starts
/// from it, and saving puts the new file and end date on the same document.
class DocumentUploadScreen extends ConsumerStatefulWidget {
  const DocumentUploadScreen({super.key, this.renewDocumentId});

  /// The document being renewed; null for an ordinary new document.
  final String? renewDocumentId;

  @override
  ConsumerState<DocumentUploadScreen> createState() =>
      _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends ConsumerState<DocumentUploadScreen> {
  static const UpgradeSheetConfig _limitUpgrade = UpgradeSheetConfig(
    headline: 'Unlock Unlimited Documents',
    reason: 'Your Document Vault is full on the Free plan.',
    features: [
      'Unlimited document storage',
      'Smart scan fills in the details for you',
      'Full-text search across all docs',
    ],
    triggerKey: 'doc_limit',
  );

  @override
  void initState() {
    super.initState();
    // Like the renewal below: apply the default category when the screen
    // starts and when the categories (re)load, never from build().
    ref.listenManual(
      documentCategoriesProvider,
      (_, next) => _useDefaultCategory(next.value),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _useDefaultCategory(ref.read(documentCategoriesProvider).value),
    );
    final renewId = widget.renewDocumentId;
    if (renewId == null) return;
    // Apply the renewal ONCE, when the screen starts (and if the old
    // document's details arrive or reload later). Re-applying on every
    // rebuild wrote the renewal back into the form after it was closed and
    // reset, so the next ordinary "new document" opened as that renewal.
    ref.listenManual(
      renewalSourceProvider(renewId),
      (_, next) => _applyRenewal(next.value),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _applyRenewal(ref.read(renewalSourceProvider(renewId)).value),
    );
  }

  void _useDefaultCategory(List<DocumentCategory>? categories) {
    if (categories == null || !mounted) return;
    ref.read(documentUploadProvider.notifier).useDefaultCategory(categories);
  }

  void _applyRenewal(RenewalSource? source) {
    if (source == null || !mounted) return;
    ref.read(documentUploadProvider.notifier).applyRenewal(source);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DocumentUploadState>(documentUploadProvider, (prev, next) {
      _onSaved(context, ref, prev, next);
      _onFailed(context, ref, prev, next);
    });

    final state = ref.watch(documentUploadProvider);
    final categories = ref.watch(documentCategoriesProvider);
    final notifier = ref.read(documentUploadProvider.notifier);
    final renewId = widget.renewDocumentId;
    final renewal = renewId == null
        ? null
        : ref.watch(renewalSourceProvider(renewId));
    return PopScope(
      canPop: !state.isSaving,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) DocumentFlow.reset(ref);
      },
      child: Scaffold(
        backgroundColor: AuroraColors.paper,
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: context.aurora.contentMaxWidth,
              ),
              child: Column(
                children: [
                  UploadHeader(
                    onCancel: state.isSaving ? null : () => context.pop(),
                    onSave: state.canSave && !state.isSaving
                        ? notifier.submit
                        : null,
                    saving: state.isSaving,
                  ),
                  if (state.isSaving)
                    UploadProgressBar(progress: state.progress),
                  Expanded(
                    child: renewal != null && renewal.hasError
                        ? ErrorView(
                            message: DocsCopy.renewalLoadError,
                            onRetry: () =>
                                ref.invalidate(renewalSourceProvider(renewId!)),
                          )
                        : categories.when(
                            loading: () => const UploadFormSkeleton(),
                            error: (_, _) => ErrorView(
                              message:
                                  'We could not load your categories. '
                                  'Check your connection and try again.',
                              onRetry: () =>
                                  ref.invalidate(documentCategoriesProvider),
                            ),
                            // A renewal waits for the old document's details
                            // so the form opens already filled in.
                            data: (list) => renewId != null && !state.isRenewal
                                ? const UploadFormSkeleton()
                                : UploadFormBody(categories: list),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onSaved(
    BuildContext context,
    WidgetRef ref,
    DocumentUploadState? prev,
    DocumentUploadState next,
  ) {
    if (prev?.phase == UploadPhase.success ||
        next.phase != UploadPhase.success) {
      return;
    }
    final id = next.savedDocumentId;
    HapticFeedback.mediumImpact();
    SnackbarService.showSuccess(
      context,
      next.isRenewal ? DocsCopy.renewalSaved : 'Document saved',
    );
    DocumentFlow.reset(ref);
    if (id == null) {
      context.pop();
      return;
    }
    context.pushReplacement(
      AppRoutes.documentDetail.replaceFirst(':documentId', id),
    );
  }

  void _onFailed(
    BuildContext context,
    WidgetRef ref,
    DocumentUploadState? prev,
    DocumentUploadState next,
  ) {
    final failure = next.failure;
    if (failure == null || failure == prev?.failure) return;
    ref.read(documentUploadProvider.notifier).clearFailure();
    switch (failure) {
      case UploadFailure.limitReached:
        UpgradeSheet.show(context, config: _limitUpgrade);
      case UploadFailure.generic:
        SnackbarService.showError(
          context,
          'Upload failed',
          subtitle: 'Your file is still here. Tap Save to try again.',
        );
    }
  }
}
