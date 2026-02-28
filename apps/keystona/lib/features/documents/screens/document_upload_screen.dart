import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/document_upload_state.dart';
import '../providers/document_upload_provider.dart';
import '../widgets/upload_category_step.dart';
import '../widgets/upload_metadata_step.dart';
import '../widgets/upload_progress_step.dart';
import '../widgets/upload_source_sheet.dart';

/// Multi-step wizard for uploading a document to the vault.
///
/// Step flow:
///   source picker → category → metadata → progress/success
///
/// The source picker opens automatically on first frame. If the user cancels,
/// the screen pops back to the document list.
class DocumentUploadScreen extends ConsumerStatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  ConsumerState<DocumentUploadScreen> createState() =>
      _DocumentUploadScreenState();
}

class _DocumentUploadScreenState
    extends ConsumerState<DocumentUploadScreen> {
  bool _sourcePickerShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showSourcePicker();
    });
  }

  Future<void> _showSourcePicker() async {
    _sourcePickerShown = true;
    bool filePicked = false;

    await UploadSourceSheet.show(
      context,
      ref,
      onFilePicked: () => filePicked = true,
    );

    // If no file was picked (user cancelled), pop back.
    if (!filePicked && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentUploadProvider);

    // Nothing to show until a file is selected.
    if (state.file == null && !_sourcePickerShown) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final title = _titleForStep(state.step);
    final canPop = state.step == DocumentUploadStep.category ||
        state.step == DocumentUploadStep.metadata;

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !canPop) return;
        if (state.step == DocumentUploadStep.metadata) {
          ref.read(documentUploadProvider.notifier).goBack();
        }
      },
      child: Platform.isIOS ? _IOSScaffold(
        title: title,
        step: state.step,
        onBack: canPop ? _handleBack : null,
        child: _stepContent(state),
      ) : _MaterialScaffold(
        title: title,
        step: state.step,
        onBack: canPop ? _handleBack : null,
        child: _stepContent(state),
      ),
    );
  }

  Widget _stepContent(DocumentUploadState state) {
    return switch (state.step) {
      DocumentUploadStep.category => UploadCategoryStep(
          onNext: () {},
        ),
      DocumentUploadStep.metadata => UploadMetadataStep(
          onNext: () {},
          onBack: _handleBack,
        ),
      DocumentUploadStep.uploading ||
      DocumentUploadStep.success =>
        UploadProgressStep(
          onDone: () {
            // Reset provider state before popping so the next upload starts fresh.
            ref.invalidate(documentUploadProvider);
            context.pop();
          },
          onRetry: () =>
              ref.read(documentUploadProvider.notifier).retryUpload(),
        ),
    };
  }

  void _handleBack() {
    final step = ref.read(documentUploadProvider).step;
    if (step == DocumentUploadStep.metadata) {
      ref.read(documentUploadProvider.notifier).goBack();
    } else {
      context.pop();
    }
  }

  String _titleForStep(DocumentUploadStep step) {
    switch (step) {
      case DocumentUploadStep.category:
        return 'Add Document';
      case DocumentUploadStep.metadata:
        return 'Document Details';
      case DocumentUploadStep.uploading:
        return 'Uploading';
      case DocumentUploadStep.success:
        return 'Saved';
    }
  }
}

// ── iOS scaffold ──────────────────────────────────────────────────────────────

class _IOSScaffold extends StatelessWidget {
  const _IOSScaffold({
    required this.title,
    required this.step,
    required this.onBack,
    required this.child,
  });

  final String title;
  final DocumentUploadStep step;
  final VoidCallback? onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(title),
        leading: onBack != null
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onBack,
                child: const Icon(CupertinoIcons.back),
              )
            : const SizedBox.shrink(),
        trailing: step == DocumentUploadStep.uploading ||
                step == DocumentUploadStep.success
            ? const SizedBox.shrink()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context, rootNavigator: true)
                    .maybePop(),
                child: const Text('Cancel'),
              ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.md,
            AppSizes.md,
            AppSizes.md,
            AppSizes.lg,
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── Material scaffold ──────────────────────────────────────────────────────────

class _MaterialScaffold extends StatelessWidget {
  const _MaterialScaffold({
    required this.title,
    required this.step,
    required this.onBack,
    required this.child,
  });

  final String title;
  final DocumentUploadStep step;
  final VoidCallback? onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isTerminal = step == DocumentUploadStep.uploading ||
        step == DocumentUploadStep.success;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: AppTextStyles.h3),
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              )
            : null,
        actions: isTerminal
            ? null
            : [
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.md,
            AppSizes.md,
            AppSizes.md,
            AppSizes.lg,
          ),
          child: child,
        ),
      ),
    );
  }
}
