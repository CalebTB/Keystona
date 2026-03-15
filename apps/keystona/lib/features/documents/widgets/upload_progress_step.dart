import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/upgrade_sheet.dart' show UpgradeSheet, UpgradeSheetConfig;
import '../models/document_upload_state.dart';
import '../providers/document_upload_provider.dart';

/// Step 3 of the upload wizard — upload progress and completion.
///
/// Shows an animated linear progress bar while uploading. On success, shows
/// a confirmation message. On error, shows the error with a retry button.
class UploadProgressStep extends ConsumerStatefulWidget {
  const UploadProgressStep({
    super.key,
    required this.onDone,
    required this.onRetry,
  });

  /// Called after a successful upload. Typically pops the wizard.
  final VoidCallback onDone;

  /// Called when the user taps "Retry" on an error.
  final VoidCallback onRetry;

  @override
  ConsumerState<UploadProgressStep> createState() =>
      _UploadProgressStepState();
}

class _UploadProgressStepState extends ConsumerState<UploadProgressStep> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentUploadProvider);

    if (state.step == DocumentUploadStep.success) {
      return _SuccessView(
        documentName: state.uploadedDocument?.name ?? state.name,
        onDone: widget.onDone,
      );
    }

    if (state.errorMessage != null) {
      if (state.errorMessage == 'free_tier') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          UpgradeSheet.show(
            context,
            config: const UpgradeSheetConfig(
              headline: 'Unlock Unlimited Documents',
              reason:
                  'Your Document Vault is full with 25 documents on the Free plan.',
              features: [
                'Unlimited document storage',
                'Full-text search across all docs',
                'Home health score tracking',
                'Weather-based maintenance alerts',
              ],
              triggerKey: 'doc_limit',
            ),
          );
        });
        return _ErrorView(
          message:
              "You've reached the 25 document limit on the free plan.",
          onRetry: null,
        );
      }

      return _ErrorView(
        message: state.errorMessage!,
        onRetry: widget.onRetry,
      );
    }

    // Uploading — show animated progress bar.
    return _ProgressView(progress: state.uploadProgress);
  }
}

// ── Progress view ──────────────────────────────────────────────────────────────

class _ProgressView extends StatelessWidget {
  const _ProgressView({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _AnimatedUploadIcon(),
            const SizedBox(height: AppSizes.xl),
            Text(
              progress < 0.5 ? 'Preparing upload…' : 'Uploading…',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'This may take a moment.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSizes.xl),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              child: LinearProgressIndicator(
                value: progress < 0.05 ? null : progress,
                minHeight: 6,
                backgroundColor: AppColors.gray200,
                valueColor: const AlwaysStoppedAnimation(AppColors.deepNavy),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Success view ───────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.documentName,
    required this.onDone,
  });

  final String documentName;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: AppSizes.iconLg,
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            Text('Document saved!', style: AppTextStyles.h2),
            const SizedBox(height: AppSizes.sm),
            Text(
              '"$documentName" has been added to your vault.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.xl),
            FilledButton(
              onPressed: onDone,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.deepNavy,
                minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
              ),
              child: Text(
                'Done',
                style: AppTextStyles.button
                    .copyWith(color: AppColors.textInverse),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error view ─────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: AppSizes.iconLg,
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            Text('Upload failed', style: AppTextStyles.h3),
            const SizedBox(height: AppSizes.sm),
            Text(
              message,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSizes.xl),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.deepNavy,
                  minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                ),
                child: Text(
                  'Try Again',
                  style: AppTextStyles.button
                      .copyWith(color: AppColors.textInverse),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Animated upload icon ──────────────────────────────────────────────────────

class _AnimatedUploadIcon extends StatefulWidget {
  const _AnimatedUploadIcon();

  @override
  State<_AnimatedUploadIcon> createState() => _AnimatedUploadIconState();
}

class _AnimatedUploadIconState extends State<_AnimatedUploadIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          color: AppColors.deepNavy,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.upload_rounded,
          color: Colors.white,
          size: AppSizes.iconLg,
        ),
      ),
    );
  }
}
