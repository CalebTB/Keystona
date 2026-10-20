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
import '../models/document_upload_state.dart';
import '../providers/document_categories_provider.dart';
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
/// With [renewDocumentId] it renews that document: the form starts from the
/// old one and, once saved, the old one is marked replaced.
class DocumentUploadScreen extends ConsumerWidget {
  const DocumentUploadScreen({super.key, this.renewDocumentId});

  /// The document being renewed; null for an ordinary new document.
  final String? renewDocumentId;

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
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<DocumentUploadState>(documentUploadProvider, (prev, next) {
      _onSaved(context, ref, prev, next);
      _onFailed(context, ref, prev, next);
    });

    final state = ref.watch(documentUploadProvider);
    final categories = ref.watch(documentCategoriesProvider);
    final notifier = ref.read(documentUploadProvider.notifier);
    ref.listen(documentCategoriesProvider, (_, next) {
      final list = next.value;
      if (list != null) notifier.useDefaultCategory(list);
    });
    final renewId = renewDocumentId;
    final renewal = renewId == null
        ? null
        : ref.watch(renewalSourceProvider(renewId));
    if (renewId != null) {
      ref.listen(renewalSourceProvider(renewId), (_, next) {
        final source = next.value;
        if (source != null) notifier.applyRenewal(source);
      });
      final source = renewal?.value;
      if (source != null) {
        // Already cached on the first frame: no listener event fires.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) notifier.applyRenewal(source);
        });
      }
    }
    final loaded = categories.value;
    if (loaded != null) {
      // First frame with categories already cached: no listener event fires.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) notifier.useDefaultCategory(loaded);
      });
    }

    return PopScope(
      canPop: !state.isSaving,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) ref.invalidate(documentUploadProvider);
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
    final id = next.uploadedDocument?.id;
    HapticFeedback.mediumImpact();
    SnackbarService.showSuccess(context, 'Document saved');
    if (next.renewalMarkFailed) {
      SnackbarService.showWarning(
        context,
        DocsCopy.renewalMarkFailed,
        subtitle: DocsCopy.renewalMarkFailedHint,
      );
    }
    ref.invalidate(documentUploadProvider);
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
